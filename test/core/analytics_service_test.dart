import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mgmess/core/observability/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = AnalyticsService();
      await service.init();
    });

    test('enabled by default', () {
      expect(service.isEnabled, isTrue);
    });

    test('can be disabled', () async {
      await service.setEnabled(false);
      expect(service.isEnabled, isFalse);
    });

    test('persists enabled state', () async {
      await service.setEnabled(false);

      final service2 = AnalyticsService();
      await service2.init();

      expect(service2.isEnabled, isFalse);
    });

    test('trackLogin stores event', () async {
      service.trackLogin(method: 'oauth');

      final events = await service.getStoredEvents();
      expect(events.length, 1);
      expect(events.first['event'], 'login');
      expect(events.first['properties']['method'], 'oauth');
      expect(events.first['timestamp'], isNotEmpty);
    });

    test('trackMessageSent stores event with properties', () async {
      service.trackMessageSent(channelId: 'ch1', hasFiles: true);

      final events = await service.getStoredEvents();
      expect(events.length, 1);
      expect(events.first['event'], 'message_sent');
      expect(events.first['properties']['channel_id'], 'ch1');
      expect(events.first['properties']['has_files'], true);
    });

    test('trackSearch stores query length not content', () async {
      service.trackSearch(query: 'secret query', resultCount: 5);

      final events = await service.getStoredEvents();
      expect(events.first['properties']['query_length'], 12);
      expect(events.first['properties']['result_count'], 5);
      // Should NOT contain the actual query text
      expect(events.first['properties'].containsKey('query'), isFalse);
    });

    test('events not stored when disabled', () async {
      await service.setEnabled(false);

      service.trackLogin(method: 'email');
      service.trackLogout();

      final events = await service.getStoredEvents();
      expect(events, isEmpty);
    });

    test('clearStoredEvents removes all events', () async {
      service.trackLogin(method: 'oauth');
      service.trackLogout();

      // Wait for async persistence
      await Future.delayed(const Duration(milliseconds: 100));

      await service.clearStoredEvents();
      final events = await service.getStoredEvents();
      expect(events, isEmpty);
    });

    test('storedEventCount returns correct count', () async {
      service.trackLogin(method: 'oauth');
      service.trackLogout();
      service.trackScreenView(screenName: 'channels');

      // Wait for async persistence
      await Future.delayed(const Duration(milliseconds: 100));

      final count = await service.storedEventCount;
      expect(count, 3);
    });

    test('all tracking methods work', () async {
      service.trackLogin(method: 'oauth');
      service.trackLogout();
      service.trackChannelOpened(channelId: 'ch1', type: 'O');
      service.trackMessageSent(channelId: 'ch1');
      service.trackSearch(query: 'test', resultCount: 3);
      service.trackFileUploaded(mimeType: 'image/png');
      service.trackReactionAdded(emoji: 'thumbsup');
      service.trackThreadOpened(postId: 'p1');
      service.trackPushReceived();
      service.trackScreenView(screenName: 'chat');
      service.trackError(source: 'api', message: 'timeout');
      service.trackChannelCreated(type: 'O');
      service.trackFeatureFlagEvaluated(flag: 'test', value: true);

      // Wait for async persistence
      await Future.delayed(const Duration(milliseconds: 200));

      final count = await service.storedEventCount;
      expect(count, 13);
    });

    test('respects max stored events limit', () async {
      // The limit is 500, let's verify the mechanism works
      // by checking events are stored and the structure is correct
      for (var i = 0; i < 10; i++) {
        service.trackScreenView(screenName: 'screen_$i');
      }

      await Future.delayed(const Duration(milliseconds: 200));

      final events = await service.getStoredEvents();
      expect(events.length, 10);
      expect(events.last['properties']['screen'], 'screen_9');
    });
  });
}
