import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/data/services/ws_post_parser_impl.dart';

void main() {
  late WsPostParserImpl parser;

  setUp(() {
    parser = WsPostParserImpl();
  });

  group('WsPostParserImpl', () {
    test('parses valid JSON post with all fields', () {
      final json = jsonEncode({
        'id': 'post1',
        'channel_id': 'ch1',
        'user_id': 'user1',
        'root_id': 'root1',
        'message': 'Hello world',
        'create_at': 1700000000000,
        'update_at': 1700000001000,
        'delete_at': 0,
        'edit_at': 0,
        'type': '',
        'is_pinned': true,
        'reply_count': 3,
        'file_ids': ['file1', 'file2'],
        'props': {'key': 'value'},
        'metadata': {
          'reactions': [
            {'emoji_name': 'thumbsup'},
            {'emoji_name': 'thumbsup'},
            {'emoji_name': 'heart'},
          ],
        },
      });

      final post = parser.parsePost(json);

      expect(post, isNotNull);
      expect(post!.id, 'post1');
      expect(post.channelId, 'ch1');
      expect(post.userId, 'user1');
      expect(post.rootId, 'root1');
      expect(post.message, 'Hello world');
      expect(post.createAt, 1700000000000);
      expect(post.isPinned, true);
      expect(post.replyCount, 3);
      expect(post.fileIds, ['file1', 'file2']);
      expect(post.reactions, {'thumbsup': 2, 'heart': 1});
      expect(post.metadata, {'key': 'value'});
    });

    test('parses valid JSON post with minimal fields', () {
      final json = jsonEncode({
        'id': 'post2',
        'channel_id': 'ch2',
        'user_id': 'user2',
        'message': 'Hi',
      });

      final post = parser.parsePost(json);

      expect(post, isNotNull);
      expect(post!.id, 'post2');
      expect(post.channelId, 'ch2');
      expect(post.userId, 'user2');
      expect(post.message, 'Hi');
      expect(post.rootId, '');
      expect(post.isPinned, false);
      expect(post.fileIds, isEmpty);
      expect(post.reactions, isEmpty);
    });

    test('returns null for invalid JSON', () {
      final result = parser.parsePost('not a json {{{');
      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = parser.parsePost('');
      expect(result, isNull);
    });

    test('returns null for JSON array instead of object', () {
      final result = parser.parsePost('[1, 2, 3]');
      expect(result, isNull);
    });

    test('parses JSON with extra unknown fields without error', () {
      final json = jsonEncode({
        'id': 'post3',
        'channel_id': 'ch3',
        'user_id': 'user3',
        'message': 'test',
        'unknown_field': 'value',
        'another_field': 42,
      });

      final post = parser.parsePost(json);

      expect(post, isNotNull);
      expect(post!.id, 'post3');
      expect(post.message, 'test');
    });

    test('parses JSON with missing optional fields', () {
      final json = jsonEncode({
        'id': 'post4',
        'channel_id': 'ch4',
        'user_id': 'user4',
      });

      final post = parser.parsePost(json);

      expect(post, isNotNull);
      expect(post!.message, '');
      expect(post.createAt, 0);
      expect(post.updateAt, 0);
      expect(post.deleteAt, 0);
      expect(post.editAt, 0);
      expect(post.type, '');
      expect(post.isPinned, false);
      expect(post.replyCount, 0);
    });

    test('parses forwarded post from permalink embed', () {
      final json = jsonEncode({
        'id': 'post5',
        'channel_id': 'ch5',
        'user_id': 'user5',
        'message': 'Check this out',
        'metadata': {
          'embeds': [
            {
              'type': 'permalink',
              'data': {
                'post': {'message': 'Original message'},
                'channel_display_name': 'General',
              },
            },
          ],
        },
      });

      final post = parser.parsePost(json);

      expect(post, isNotNull);
      expect(post!.forwardedPostMessage, 'Original message');
      expect(post.forwardedChannelName, 'General');
    });

    test('parses post with priority metadata', () {
      final json = jsonEncode({
        'id': 'post6',
        'channel_id': 'ch6',
        'user_id': 'user6',
        'message': 'Urgent!',
        'metadata': {
          'priority': {
            'priority': 'urgent',
            'requested_ack': false,
          },
        },
      });

      final post = parser.parsePost(json);

      expect(post, isNotNull);
      expect(post!.priority, 'urgent');
      expect(post.isUrgent, true);
    });
  });
}
