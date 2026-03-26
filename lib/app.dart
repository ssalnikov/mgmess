import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'core/auth/biometric_service.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/di/server_session.dart';
import 'core/di/session_manager.dart';
import 'core/notifications/notification_service.dart';
import 'presentation/blocs/server/server_list_cubit.dart';
import 'core/l10n/l10n.dart';
import 'core/observability/analytics_service.dart';
import 'core/observability/crash_reporting.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/connectivity/connectivity_cubit.dart';
import 'presentation/blocs/notification/notification_event.dart';
import 'presentation/blocs/locale/locale_cubit.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/blocs/websocket/websocket_event.dart';
import 'presentation/screens/auth/biometric_lock_screen.dart';
import 'presentation/screens/server/server_url_screen.dart';
import 'presentation/widgets/server_session_provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final _logger = Logger(printer: SimplePrinter());
  late bool _serverReady;

  ServerSession? _session;
  ConnectivityCubit? _connectivityCubit;
  late ThemeCubit _themeCubit;
  late LocaleCubit _localeCubit;
  ServerListCubit? _serverListCubit;
  AppRouter? _appRouter;
  StreamSubscription? _wsEventSub;
  StreamSubscription? _serverSwitchSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<NotificationTapPayload>? _notificationTapSub;
  StreamSubscription<Uri>? _oauthLinkSub;

  /// WS-event subscriptions for background sessions (notifications).
  final Map<String, StreamSubscription> _bgWsEventSubs = {};

  /// Channel to navigate to after a server switch triggered by a notification tap.
  String? _pendingDeepLinkChannelId;

  bool _biometricLocked = false;
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeCubit = AppConfig.isServerConfigured
        ? sl<ThemeCubit>()
        : ThemeCubit();
    _localeCubit = AppConfig.isServerConfigured
        ? sl<LocaleCubit>()
        : LocaleCubit();
    _serverReady = AppConfig.isServerConfigured;
    if (_serverReady) {
      _initSession();
      _checkBiometricOnLaunch();
    }
  }

  void _initSession() {
    _session = sl<SessionManager>().activeSession!;
    _connectivityCubit = sl<ConnectivityCubit>();
    _appRouter = AppRouter(authBloc: _session!.authBloc);
    _session!.authBloc.add(const AuthCheckSession());

    _serverListCubit = sl<ServerListCubit>();
    _serverListCubit!.load();
    _serverSwitchSub?.cancel();
    _serverSwitchSub = _serverListCubit!.stream.listen((state) {
      final newSession = sl<SessionManager>().activeSession;
      if (newSession != null && newSession.accountId != _session?.accountId) {
        _wsEventSub?.cancel();
        _cancelBackgroundSubscriptions();
        setState(() {
          _session = newSession;
          _appRouter = AppRouter(authBloc: _session!.authBloc);
          _session!.authBloc.add(const AuthCheckSession());
        });
      }
    });

    _notificationTapSub?.cancel();
    _notificationTapSub =
        sl<NotificationService>().onNotificationTap.listen(_onNotificationTap);

    _listenForOAuthDeepLinks();
  }

  /// Listen for OAuth deep-link callbacks (`mmauth://oauth/callback`).
  ///
  /// The listener lives in [App] (always mounted) rather than in
  /// [AuthScreen] so that the callback is never lost if the active
  /// session changes while the user is in the browser.
  void _listenForOAuthDeepLinks() {
    _oauthLinkSub?.cancel();
    final appLinks = AppLinks();
    _oauthLinkSub = appLinks.uriLinkStream.listen(_onOAuthCallback);
  }

  /// Route an OAuth callback to the correct [AuthBloc].
  void _onOAuthCallback(Uri uri) {
    if (uri.scheme != AppConfig.callbackScheme) return;

    final token = uri.queryParameters['MMAUTHTOKEN'];
    final csrf = uri.queryParameters['MMCSRF'];
    if (token == null || token.isEmpty) return;

    final sm = sl<SessionManager>();
    final targetAccountId = sm.consumePendingOAuth() ?? _session?.accountId;
    if (targetAccountId == null) return;

    // Find the target session.
    final targetSession = sm.getSession(targetAccountId);
    if (targetSession == null) {
      _logger.w('OAuth callback for unknown account $targetAccountId');
      return;
    }

    // Deliver tokens to the target session's AuthBloc.
    targetSession.authBloc.add(
      AuthOAuthCompleted(token: token, csrfToken: csrf),
    );

    // If the target is not the active session, switch to it.
    if (targetAccountId != _session?.accountId) {
      _serverListCubit?.switchServer(targetAccountId);
    }
  }

  Future<void> _checkBiometricOnLaunch() async {
    final bio = sl<BiometricService>();
    final enabled = await bio.isEnabled();
    final available = await bio.isAvailable();
    if (enabled && available) {
      setState(() => _biometricLocked = true);
    }
  }

  void _onServerConfigured() {
    _themeCubit.close();
    _localeCubit.close();
    setState(() {
      _serverReady = true;
      _themeCubit = sl<ThemeCubit>();
      _localeCubit = sl<LocaleCubit>();
      _initSession();
      _checkBiometricOnLaunch();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      _checkBiometricOnResume();
    }
  }

  Future<void> _checkBiometricOnResume() async {
    if (!_serverReady) return;
    final bio = sl<BiometricService>();
    final enabled = await bio.isEnabled();
    final available = await bio.isAvailable();
    if (enabled && available) {
      setState(() => _biometricLocked = true);
    }
  }

  /// Connect WebSocket and subscribe to WS events for every background
  /// session that has a stored token.  Their [NotificationBloc]s will
  /// show local notifications with a server-name prefix.
  Future<void> _connectBackgroundSessions() async {
    _cancelBackgroundSubscriptions();

    final sm = sl<SessionManager>();
    await sm.initBackgroundSessions();

    for (final session in sm.backgroundSessions) {
      _bgWsEventSubs[session.accountId] =
          session.webSocketBloc.wsEvents.listen((wsEvent) {
        session.notificationBloc.add(
          NotificationWsEvent(wsEvent: wsEvent),
        );
      });
    }
  }

  void _cancelBackgroundSubscriptions() {
    for (final sub in _bgWsEventSubs.values) {
      sub.cancel();
    }
    _bgWsEventSubs.clear();
  }

  /// Handle notification tap — switch server if needed, navigate to channel.
  void _onNotificationTap(NotificationTapPayload payload) {
    final channelId = payload.channelId;
    if (channelId == null || channelId.isEmpty) return;

    final sm = sl<SessionManager>();

    // Determine which account owns this notification.
    String? targetAccountId = payload.accountId;
    if (targetAccountId == null && payload.serverUrl != null) {
      final target = sm.findSessionByServerUrl(payload.serverUrl!);
      targetAccountId = target?.accountId;
    }

    final needsSwitch =
        targetAccountId != null && targetAccountId != _session?.accountId;

    if (needsSwitch) {
      // Switch server, store channel for post-auth navigation.
      _pendingDeepLinkChannelId = channelId;
      _serverListCubit?.switchServer(targetAccountId);
    } else {
      // Same server — navigate immediately.
      _appRouter?.router.go(RouteNames.chatPath(channelId));
    }
  }

  /// Get the FCM token from [NotificationService] and register it on every
  /// server session.  Also subscribe to token refresh so re-registration
  /// happens automatically when Firebase rotates the token.
  Future<void> _registerFcmTokenOnAllServers() async {
    final notifService = sl<NotificationService>();
    final sm = sl<SessionManager>();

    final token = await notifService.getToken();
    if (token != null) {
      await sm.registerFcmTokenOnAllSessions(token);
    }

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = notifService.onTokenRefresh?.listen((newToken) async {
      await sm.registerFcmTokenOnAllSessions(newToken);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wsEventSub?.cancel();
    _serverSwitchSub?.cancel();
    _tokenRefreshSub?.cancel();
    _notificationTapSub?.cancel();
    _oauthLinkSub?.cancel();
    _cancelBackgroundSubscriptions();
    _connectivityCubit?.close();
    // Per-server BLoCs are owned by ServerSession — not closed here.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_serverReady) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _themeCubit),
          BlocProvider.value(value: _localeCubit),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return BlocBuilder<LocaleCubit, LocaleState>(
              builder: (context, localeState) {
                return MaterialApp(
                  title: 'MGMess',
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: themeState.themeMode,
                  locale: localeState.locale,
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: ServerUrlScreen(onServerConfigured: _onServerConfigured),
                );
              },
            );
          },
        ),
      );
    }

    final session = _session!;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _themeCubit),
        BlocProvider.value(value: _localeCubit),
        BlocProvider.value(value: _serverListCubit!),
      ],
      child: ServerSessionProvider(
        session: session,
        child: MultiBlocProvider(
          key: ValueKey(session.accountId),
          providers: [
            BlocProvider.value(value: session.authBloc),
            BlocProvider.value(value: session.webSocketBloc),
            BlocProvider.value(value: _connectivityCubit!),
            BlocProvider.value(value: session.notificationBloc),
            BlocProvider.value(value: session.userStatusCubit),
          ],
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                session.webSocketBloc.add(const WebSocketConnect());
                session.notificationBloc.add(
                  NotificationInit(userId: state.user.id),
                );
                session.userStatusCubit.subscribeToWs(
                  session.webSocketBloc.wsEvents,
                );
                session.userStatusCubit.setCustomStatusFromUser(state.user);
                _wsEventSub?.cancel();
                _wsEventSub =
                    session.webSocketBloc.wsEvents.listen((wsEvent) {
                  session.notificationBloc.add(
                    NotificationWsEvent(wsEvent: wsEvent),
                  );
                });
                // Connect WS for background sessions so they can
                // show notifications while the active server is in use.
                _connectBackgroundSessions();
                // Register FCM token on all servers (active + background)
                _registerFcmTokenOnAllServers();
                // Observability: set user context
                CrashReporting.setUser(
                  userId: state.user.id,
                  username: state.user.username,
                );
                sl<AnalyticsService>().trackLogin(method: 'session');
                // Navigate to channel if a notification tap triggered a server switch.
                if (_pendingDeepLinkChannelId != null) {
                  final channelId = _pendingDeepLinkChannelId!;
                  _pendingDeepLinkChannelId = null;
                  // Defer to allow the router to settle after auth redirect.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _appRouter?.router.go(RouteNames.chatPath(channelId));
                  });
                }
              } else if (state is AuthUnauthenticated) {
                session.webSocketBloc.add(const WebSocketDisconnect());
                _wsEventSub?.cancel();
                session.notificationBloc.add(const NotificationLogout());
                CrashReporting.clearUser();
                sl<AnalyticsService>().trackLogout();
                try {
                  AppBadgePlus.updateBadge(0);
                } catch (_) {}
              }
            },
            child: BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                return BlocBuilder<LocaleCubit, LocaleState>(
                  builder: (context, localeState) {
                    return MaterialApp.router(
                      title: 'MGMess',
                      theme: AppTheme.light,
                      darkTheme: AppTheme.dark,
                      themeMode: themeState.themeMode,
                      locale: localeState.locale,
                      routerConfig: _appRouter!.router,
                      debugShowCheckedModeBanner: false,
                      localizationsDelegates: AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                      builder: (context, child) {
                        if (_biometricLocked) {
                          return BiometricLockScreen(
                            onAuthenticated: () {
                              setState(() => _biometricLocked = false);
                            },
                          );
                        }
                        return child ?? const SizedBox.shrink();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
