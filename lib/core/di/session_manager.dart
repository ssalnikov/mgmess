import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:logger/logger.dart';

import '../../domain/entities/server_account.dart';
import '../../presentation/blocs/notification/notification_event.dart';
import '../../presentation/blocs/websocket/websocket_event.dart';
import '../network/network_info.dart';
import '../notifications/notification_service.dart';
import '../storage/secure_storage.dart';
import 'server_session.dart';

/// Manages per-server [ServerSession] instances.
///
/// Holds all sessions and tracks the currently active one.
/// Shared dependencies ([SecureStorage], [NetworkInfo], [NotificationService])
/// are injected once and reused across all sessions.
class SessionManager {
  final SecureStorage _secureStorage;
  final NetworkInfo _networkInfo;
  final NotificationService _notificationService;
  final _logger = Logger(printer: SimplePrinter());

  final Map<String, ServerSession> _sessions = {};
  String? _activeSessionId;

  /// The account currently going through the OAuth flow (one at a time).
  String? _pendingOAuthAccountId;

  SessionManager({
    required SecureStorage secureStorage,
    required NetworkInfo networkInfo,
    required NotificationService notificationService,
  })  : _secureStorage = secureStorage,
        _networkInfo = networkInfo,
        _notificationService = notificationService;

  /// Currently active session, or null if none.
  ServerSession? get activeSession =>
      _activeSessionId != null ? _sessions[_activeSessionId] : null;

  /// All live sessions.
  List<ServerSession> get allSessions => _sessions.values.toList();

  /// Get session by account id, or null.
  ServerSession? getSession(String accountId) => _sessions[accountId];

  /// All sessions except the currently active one.
  List<ServerSession> get backgroundSessions => _sessions.entries
      .where((e) => e.key != _activeSessionId)
      .map((e) => e.value)
      .toList();

  /// Whether any session exists.
  bool get hasSessions => _sessions.isNotEmpty;

  /// Create and store a session for the given [account].
  /// Does not activate it — call [switchTo] afterwards.
  ServerSession createSession(ServerAccount account) {
    if (_sessions.containsKey(account.id)) {
      return _sessions[account.id]!;
    }

    final session = ServerSession(
      accountId: account.id,
      serverUrl: account.serverUrl,
      displayName: account.displayName.isNotEmpty
          ? account.displayName
          : Uri.parse(account.serverUrl).host,
      secureStorage: _secureStorage,
      networkInfo: _networkInfo,
      notificationService: _notificationService,
    );
    _sessions[account.id] = session;
    return session;
  }

  /// Switch the active session to [accountId].
  /// The session must have been created beforehand via [createSession].
  void switchTo(String accountId) {
    assert(_sessions.containsKey(accountId),
        'Session for $accountId not found. Call createSession first.');
    _activeSessionId = accountId;
  }

  /// Remove and dispose session for [accountId].
  Future<void> removeSession(String accountId) async {
    final session = _sessions.remove(accountId);
    await session?.dispose();
    if (_activeSessionId == accountId) {
      _activeSessionId =
          _sessions.isNotEmpty ? _sessions.keys.first : null;
    }
  }

  /// Connect WebSocket and init notifications for all background sessions
  /// that have stored credentials.
  ///
  /// Called after the active session authenticates so that background
  /// sessions also receive real-time events (for notifications / badges).
  Future<void> initBackgroundSessions() async {
    for (final session in backgroundSessions) {
      final results = await Future.wait([
        _secureStorage.getAccountToken(session.accountId),
        _secureStorage.getAccountUserId(session.accountId),
      ]);
      final token = results[0];
      final userId = results[1];

      if (token != null) {
        session.webSocketBloc.add(const WebSocketConnect());
      }
      if (userId != null) {
        session.notificationBloc.add(
          NotificationInitBackground(userId: userId),
        );
      }
    }
  }

  /// Register the FCM [token] on every session that has a stored auth token.
  ///
  /// Called when the active session obtains/refreshes the FCM token so that
  /// all servers know where to deliver push notifications for this device.
  Future<void> registerFcmTokenOnAllSessions(String token) async {
    await Future.wait(
      _sessions.values.map((session) async {
        final authToken =
            await _secureStorage.getAccountToken(session.accountId);
        if (authToken != null) {
          try {
            await session.notificationRepository.registerDeviceToken(token);
          } catch (e) {
            _logger.w(
              'Failed to register FCM token on ${session.displayName}: $e',
            );
          }
        }
      }),
    );
  }

  /// Find a session whose [serverUrl] matches the given URL.
  ///
  /// Useful for routing push notifications that carry `server_url`.
  static final _trailingSlashes = RegExp(r'/+$');

  ServerSession? findSessionByServerUrl(String serverUrl) {
    final normalized = serverUrl.replaceAll(_trailingSlashes, '');
    for (final session in _sessions.values) {
      if (session.serverUrl.replaceAll(_trailingSlashes, '') == normalized) {
        return session;
      }
    }
    return null;
  }

  /// Mark [accountId] as the account currently going through OAuth.
  ///
  /// Called right before launching the OAuth browser.  When the
  /// `mmauth://oauth/callback` deep link arrives, [consumePendingOAuth]
  /// returns this id so the tokens are routed to the correct session.
  void startOAuth(String accountId) {
    _pendingOAuthAccountId = accountId;
  }

  /// Return and clear the pending-OAuth account id.
  ///
  /// Returns `null` if no OAuth is in progress.
  String? consumePendingOAuth() {
    final id = _pendingOAuthAccountId;
    _pendingOAuthAccountId = null;
    return id;
  }

  /// Sets a pre-built session as the active session. Test-only.
  @visibleForTesting
  void setTestSession(ServerSession session) {
    _sessions[session.accountId] = session;
    _activeSessionId = session.accountId;
  }

  /// Dispose all sessions.
  Future<void> dispose() async {
    for (final session in _sessions.values) {
      await session.dispose();
    }
    _sessions.clear();
    _activeSessionId = null;
  }
}
