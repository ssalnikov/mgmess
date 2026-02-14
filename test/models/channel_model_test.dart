import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/data/models/channel_model.dart';
import 'package:mgmess/domain/entities/channel.dart';

void main() {
  group('ChannelModel', () {
    const json = {
      'id': 'ch123',
      'team_id': 'team1',
      'name': 'general',
      'display_name': 'General',
      'header': 'Welcome!',
      'purpose': 'General discussion',
      'type': 'O',
      'create_at': 1000000,
      'update_at': 2000000,
      'delete_at': 0,
      'total_msg_count': 100,
      'last_post_at': 3000000,
    };

    test('fromJson creates correct model', () {
      final channel = ChannelModel.fromJson(json);
      expect(channel.id, 'ch123');
      expect(channel.teamId, 'team1');
      expect(channel.name, 'general');
      expect(channel.displayName, 'General');
      expect(channel.type, ChannelType.open);
      expect(channel.totalMsgCount, 100);
    });

    test('type mapping works correctly', () {
      expect(
        ChannelModel.fromJson({...json, 'type': 'O'}).type,
        ChannelType.open,
      );
      expect(
        ChannelModel.fromJson({...json, 'type': 'P'}).type,
        ChannelType.private_,
      );
      expect(
        ChannelModel.fromJson({...json, 'type': 'D'}).type,
        ChannelType.direct,
      );
      expect(
        ChannelModel.fromJson({...json, 'type': 'G'}).type,
        ChannelType.group,
      );
    });

    test('unreadCount calculates correctly', () {
      final channel = ChannelModel(
        id: 'ch1',
        totalMsgCount: 50,
        msgCount: 30,
      );
      expect(channel.unreadCount, 20);
      expect(channel.hasUnread, true);
    });

    test('hasUnread returns false when caught up', () {
      final channel = ChannelModel(
        id: 'ch1',
        totalMsgCount: 50,
        msgCount: 50,
      );
      expect(channel.hasUnread, false);
    });

    test('hasMention returns true with mention count', () {
      final channel = ChannelModel(id: 'ch1', mentionCount: 3);
      expect(channel.hasMention, true);
    });

    test('isDirect / isGroup / isPrivate work', () {
      expect(
        const ChannelModel(id: 'ch1', type: ChannelType.direct).isDirect,
        true,
      );
      expect(
        const ChannelModel(id: 'ch1', type: ChannelType.group).isGroup,
        true,
      );
      expect(
        const ChannelModel(id: 'ch1', type: ChannelType.private_).isPrivate,
        true,
      );
    });

    test('copyWith updates fields correctly', () {
      final channel = ChannelModel.fromJson(json);
      final updated = channel.copyWith(
        totalMsgCount: 200,
        mentionCount: 5,
      );
      expect(updated.totalMsgCount, 200);
      expect(updated.mentionCount, 5);
      expect(updated.id, channel.id); // unchanged
    });

    test('fromJson handles empty map', () {
      final channel = ChannelModel.fromJson({});
      expect(channel.id, '');
      expect(channel.type, ChannelType.open);
    });
  });
}
