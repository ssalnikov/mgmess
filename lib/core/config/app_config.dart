import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

class AppConfig {
  static const String _storageKey = 'mm_server_url';
  static const String defaultServerUrl = 'https://mm.my.games';

  static String _serverUrl = '';

  static String get serverUrl =>
      _serverUrl.isNotEmpty ? _serverUrl : defaultServerUrl;

  static bool get isServerConfigured => _serverUrl.isNotEmpty;

  static Future<void> loadFromStorage() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    _serverUrl = await storage.read(key: _storageKey) ?? '';
  }

  static Future<void> setServerUrl(String url) async {
    var normalized = url.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    _serverUrl = normalized;
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.write(key: _storageKey, value: normalized);
  }

  static Future<void> clearServerUrl() async {
    _serverUrl = '';
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.delete(key: _storageKey);
  }

  @visibleForTesting
  static set serverUrlOverride(String url) => _serverUrl = url;

  static const String apiV4 = '/api/v4';
  static const String wsPath = '/api/v4/websocket';
  static const String oauthPath = '/oauth/gitlab/mobile_login';
  static const String callbackScheme = 'mmauth';
  static const String callbackPath = '/oauth/callback';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  static const int postsPerPage = 60;
  static const int channelsPerPage = 100;

  static String get baseUrl => '$serverUrl$apiV4';
  static String get wsUrl {
    final uri = Uri.parse(serverUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$port$wsPath';
  }
  static String get oauthUrl => '$serverUrl$oauthPath?redirect_to=$callbackScheme://$callbackPath';
}
