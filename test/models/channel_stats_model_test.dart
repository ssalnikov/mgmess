import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/data/models/channel_stats_model.dart';

void main() {
  group('ChannelStatsModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'channel_id': 'ch1',
        'member_count': 42,
        'guest_count': 3,
        'pinnedpost_count': 5,
      };

      final model = ChannelStatsModel.fromJson(json);

      expect(model.channelId, 'ch1');
      expect(model.memberCount, 42);
      expect(model.guestCount, 3);
      expect(model.pinnedPostCount, 5);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final model = ChannelStatsModel.fromJson(json);

      expect(model.channelId, '');
      expect(model.memberCount, 0);
      expect(model.guestCount, 0);
      expect(model.pinnedPostCount, 0);
    });

    test('fromJson handles null values', () {
      final json = {
        'channel_id': null,
        'member_count': null,
        'guest_count': null,
        'pinnedpost_count': null,
      };

      final model = ChannelStatsModel.fromJson(json);

      expect(model.channelId, '');
      expect(model.memberCount, 0);
      expect(model.guestCount, 0);
      expect(model.pinnedPostCount, 0);
    });

    test('props works for Equatable', () {
      const a = ChannelStatsModel(
        channelId: 'ch1',
        memberCount: 10,
      );
      const b = ChannelStatsModel(
        channelId: 'ch1',
        memberCount: 10,
      );
      const c = ChannelStatsModel(
        channelId: 'ch1',
        memberCount: 20,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
