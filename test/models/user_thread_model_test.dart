import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/data/models/user_thread_model.dart';

void main() {
  group('UserThreadModel', () {
    const json = {
      'id': 'thread1',
      'reply_count': 5,
      'last_reply_at': 1700000000000,
      'last_viewed_at': 1699999000000,
      'participants': [
        {'id': 'u1'},
        {'id': 'u2'},
      ],
      'post': {
        'id': 'thread1',
        'channel_id': 'ch1',
        'user_id': 'u1',
        'message': 'Hello thread',
        'create_at': 1699000000000,
      },
      'unread_replies': 2,
      'unread_mentions': 1,
    };

    test('fromJson creates correct model', () {
      final thread = UserThreadModel.fromJson(json);
      expect(thread.id, 'thread1');
      expect(thread.replyCount, 5);
      expect(thread.lastReplyAt, 1700000000000);
      expect(thread.lastViewedAt, 1699999000000);
      expect(thread.participantIds, ['u1', 'u2']);
      expect(thread.post.id, 'thread1');
      expect(thread.post.message, 'Hello thread');
      expect(thread.unreadReplies, 2);
      expect(thread.unreadMentions, 1);
    });

    test('hasUnread returns true when unreadReplies > 0', () {
      final thread = UserThreadModel.fromJson(json);
      expect(thread.hasUnread, true);
    });

    test('hasUnread returns false when unreadReplies is 0', () {
      final thread = UserThreadModel.fromJson({
        ...json,
        'unread_replies': 0,
      });
      expect(thread.hasUnread, false);
    });

    test('fromJson handles missing fields', () {
      final thread = UserThreadModel.fromJson({
        'id': 'x',
        'post': {
          'id': 'x',
          'channel_id': 'ch',
          'user_id': 'u',
        },
      });
      expect(thread.id, 'x');
      expect(thread.replyCount, 0);
      expect(thread.lastReplyAt, 0);
      expect(thread.lastViewedAt, 0);
      expect(thread.participantIds, isEmpty);
      expect(thread.unreadReplies, 0);
      expect(thread.unreadMentions, 0);
      expect(thread.hasUnread, false);
    });

    test('fromJson handles missing post', () {
      final thread = UserThreadModel.fromJson({'id': 'x'});
      expect(thread.post.id, '');
    });

    test('fromJson parses participant string IDs', () {
      final thread = UserThreadModel.fromJson({
        ...json,
        'participants': [
          {'id': 'user-a'},
          {'id': 'user-b'},
          {'id': 'user-c'},
        ],
      });
      expect(thread.participantIds, ['user-a', 'user-b', 'user-c']);
    });

    test('equatable uses id', () {
      final t1 = UserThreadModel.fromJson(json);
      final t2 = UserThreadModel.fromJson({...json, 'reply_count': 99});
      expect(t1, equals(t2));
    });
  });
}
