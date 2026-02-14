class AppConfig {
  static const String serverUrl = 'http://localhost:8065';
  static const String apiV4 = '/api/v4';
  static const String wsPath = '/api/v4/websocket';
  static const String oauthPath = '/oauth/gitlab/mobile_login';
  static const String callbackScheme = 'mgmess';
  static const String callbackPath = '/oauth/callback';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  static const int postsPerPage = 60;
  static const int channelsPerPage = 100;

  static String get baseUrl => '$serverUrl$apiV4';
  static String get wsUrl => 'ws://${Uri.parse(serverUrl).host}:${Uri.parse(serverUrl).port}$wsPath';
  static String get oauthUrl => '$serverUrl$oauthPath?redirect_to=$callbackScheme://$callbackPath';
}
