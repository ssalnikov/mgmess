import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/data/models/post_model.dart';

void main() {
  group('PostModel', () {
    const json = {
      'id': 'post123',
      'channel_id': 'ch1',
      'user_id': 'user1',
      'root_id': '',
      'message': 'Hello world',
      'create_at': 1000000,
      'update_at': 2000000,
      'delete_at': 0,
      'edit_at': 0,
      'type': '',
      'props': {},
      'file_ids': ['file1', 'file2'],
      'is_pinned': false,
      'reply_count': 0,
      'pending_post_id': '',
      'metadata': {
        'reactions': [
          {'emoji_name': 'thumbsup'},
          {'emoji_name': 'thumbsup'},
          {'emoji_name': 'heart'},
        ],
      },
    };

    test('fromJson creates correct model', () {
      final post = PostModel.fromJson(json);
      expect(post.id, 'post123');
      expect(post.channelId, 'ch1');
      expect(post.userId, 'user1');
      expect(post.message, 'Hello world');
      expect(post.createAt, 1000000);
    });

    test('fromJson parses file_ids', () {
      final post = PostModel.fromJson(json);
      expect(post.fileIds, ['file1', 'file2']);
      expect(post.hasFiles, true);
    });

    test('fromJson parses reactions from metadata', () {
      final post = PostModel.fromJson(json);
      expect(post.reactions['thumbsup'], 2);
      expect(post.reactions['heart'], 1);
    });

    test('isDeleted works', () {
      final post = PostModel.fromJson({...json, 'delete_at': 100});
      expect(post.isDeleted, true);
    });

    test('isEdited works', () {
      final post = PostModel.fromJson({...json, 'edit_at': 100});
      expect(post.isEdited, true);
    });

    test('isSystemMessage works', () {
      final post = PostModel.fromJson({
        ...json,
        'type': 'system_join_channel',
      });
      expect(post.isSystemMessage, true);
    });

    test('isReply works', () {
      final post = PostModel.fromJson({
        ...json,
        'root_id': 'parent123',
      });
      expect(post.isReply, true);
    });

    test('toJson creates correct map for sending', () {
      final post = PostModel.fromJson(json);
      final result = post.toJson();
      expect(result['channel_id'], 'ch1');
      expect(result['message'], 'Hello world');
      expect(result['file_ids'], ['file1', 'file2']);
    });

    test('toJson omits root_id when empty', () {
      final post = PostModel.fromJson(json);
      final result = post.toJson();
      expect(result.containsKey('root_id'), false);
    });

    test('copyWith updates fields', () {
      final post = PostModel.fromJson(json);
      final updated = post.copyWith(
        message: 'Updated',
        isPinned: true,
      );
      expect(updated.message, 'Updated');
      expect(updated.isPinned, true);
      expect(updated.id, post.id);
    });

    test('fromJson handles missing fields', () {
      final post = PostModel.fromJson({
        'id': 'x',
        'channel_id': 'ch',
        'user_id': 'u',
      });
      expect(post.id, 'x');
      expect(post.message, '');
      expect(post.fileIds, isEmpty);
      expect(post.reactions, isEmpty);
    });
  });
}
