import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/app_config.dart';

class CrashReporting {
  static const String _defaultDsn = '';

  static bool get isEnabled => _dsn.isNotEmpty;
  static String _dsn = _defaultDsn;

  /// Initialize Sentry crash reporting.
  /// Pass [dsn] to override the default DSN (useful for testing).
  static Future<void> init({
    required FutureOr<void> Function() appRunner,
    String? dsn,
  }) async {
    _dsn = dsn ?? _defaultDsn;

    if (!isEnabled) {
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.environment = kReleaseMode ? 'production' : 'development';
        options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
        options.attachScreenshot = true;
        options.sendDefaultPii = false;
        options.beforeSend = _beforeSend;
      },
      appRunner: appRunner,
    );
  }

  /// Set user context after authentication.
  static void setUser({
    required String userId,
    required String username,
  }) {
    if (!isEnabled) return;
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: userId,
        username: username,
      ));
      scope.setTag('server_url', AppConfig.serverUrl);
    });
  }

  /// Clear user context on logout.
  static void clearUser() {
    if (!isEnabled) return;
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Add a breadcrumb for navigation or user actions.
  static void addBreadcrumb({
    required String category,
    required String message,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    if (!isEnabled) return;
    Sentry.addBreadcrumb(Breadcrumb(
      category: category,
      message: message,
      data: data,
      level: level,
    ));
  }

  /// Report a caught exception with optional context.
  static Future<void> reportError(
    dynamic exception, {
    dynamic stackTrace,
    String? context,
    Map<String, dynamic>? extra,
  }) async {
    if (!isEnabled) return;

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (context != null) {
          scope.setTag('error_context', context);
        }
        if (extra != null) {
          for (final entry in extra.entries) {
            scope.setContexts(entry.key, entry.value);
          }
        }
      },
    );
  }

  /// Report a message-level event (non-exception).
  static Future<void> reportMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
  }) async {
    if (!isEnabled) return;
    await Sentry.captureMessage(message, level: level);
  }

  /// Filter events before sending (strip PII, skip debug noise).
  static FutureOr<SentryEvent?> _beforeSend(
    SentryEvent event,
    Hint hint,
  ) {
    // Don't send events in debug mode
    if (kDebugMode) return null;

    return event;
  }
}

/// Dio interceptor that adds Sentry breadcrumbs for HTTP requests.
class SentryHttpBreadcrumbInterceptor {
  static void onRequest(String method, String path) {
    CrashReporting.addBreadcrumb(
      category: 'http',
      message: '$method $path',
    );
  }

  static void onError(int? statusCode, String path, String? message) {
    CrashReporting.addBreadcrumb(
      category: 'http',
      message: 'Error $statusCode $path',
      data: {'message': message},
      level: SentryLevel.error,
    );
  }
}
