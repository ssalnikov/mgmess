import 'package:flutter_test/flutter_test.dart';

import 'package:mgmess/core/observability/crash_reporting.dart';

void main() {
  group('CrashReporting', () {
    test('isEnabled is false when DSN is empty (default)', () {
      // Default DSN is empty, so Sentry is disabled
      expect(CrashReporting.isEnabled, isFalse);
    });

    test('init runs appRunner even when disabled', () async {
      var ran = false;

      await CrashReporting.init(
        appRunner: () {
          ran = true;
        },
      );

      expect(ran, isTrue);
    });

    test('setUser does not throw when disabled', () {
      // Should be a no-op, not throw
      CrashReporting.setUser(userId: 'u1', username: 'test');
    });

    test('clearUser does not throw when disabled', () {
      CrashReporting.clearUser();
    });

    test('addBreadcrumb does not throw when disabled', () {
      CrashReporting.addBreadcrumb(
        category: 'test',
        message: 'something',
      );
    });

    test('reportError does not throw when disabled', () async {
      await CrashReporting.reportError(
        Exception('test'),
        context: 'unit_test',
      );
    });

    test('reportMessage does not throw when disabled', () async {
      await CrashReporting.reportMessage('test message');
    });
  });

  group('SentryHttpBreadcrumbInterceptor', () {
    test('onRequest does not throw when Sentry disabled', () {
      SentryHttpBreadcrumbInterceptor.onRequest('GET', '/api/v4/posts');
    });

    test('onError does not throw when Sentry disabled', () {
      SentryHttpBreadcrumbInterceptor.onError(500, '/api/v4/posts', 'timeout');
    });
  });
}
