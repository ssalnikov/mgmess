import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/core/network/websocket_events.dart';
import 'package:mgmess/core/utils/date_formatter.dart';

void main() {
  group('WsEvent', () {
    test('fromJson parses correctly', () {
      final event = WsEvent.fromJson({
        'event': 'posted',
        'data': {'channel_id': 'ch1', 'post': '{}'},
        'broadcast': {'channel_id': 'ch1'},
        'seq': 5,
      });
      expect(event.event, 'posted');
      expect(event.channelId, 'ch1');
      expect(event.seq, 5);
    });

    test('fromJson handles missing fields', () {
      final event = WsEvent.fromJson({});
      expect(event.event, '');
      expect(event.channelId, isNull);
      expect(event.seq, 0);
    });

    test('channelId from broadcast takes priority', () {
      final event = WsEvent.fromJson({
        'event': 'posted',
        'data': {'channel_id': 'from_data'},
        'broadcast': {'channel_id': 'from_broadcast'},
      });
      expect(event.channelId, 'from_broadcast');
    });
  });

  group('DateFormatter', () {
    test('formatMessageTime returns empty for 0', () {
      expect(DateFormatter.formatMessageTime(0), '');
    });

    test('formatChannelTime returns empty for 0', () {
      expect(DateFormatter.formatChannelTime(0), '');
    });

    test('formatMessageTime formats recent time', () {
      final now = DateTime.now();
      final ts = now.millisecondsSinceEpoch;
      final result = DateFormatter.formatMessageTime(ts);
      expect(result, isNotEmpty);
    });

    test('formatDateSeparator returns Today for today', () {
      final ts = DateTime.now().millisecondsSinceEpoch;
      expect(DateFormatter.formatDateSeparator(ts), 'Today');
    });

    test('formatDateSeparator returns Yesterday', () {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      expect(
        DateFormatter.formatDateSeparator(
          yesterday.millisecondsSinceEpoch,
        ),
        'Yesterday',
      );
    });
  });
}
