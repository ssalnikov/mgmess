import '../../../core/error/exceptions.dart';
import '../../../domain/entities/post.dart';
import '../../models/post_model.dart';
import 'daos/post_dao.dart';
import 'mappers/post_mapper.dart';

class PostLocalDataSource {
  final PostDao _dao;

  PostLocalDataSource({required PostDao dao}) : _dao = dao;

  Future<void> cachePosts(List<Post> posts) async {
    try {
      final companions = posts.map((p) => PostMapper.toCompanion(p)).toList();
      await _dao.upsertPosts(companions);
    } catch (e) {
      throw CacheException(message: 'Failed to cache posts: $e');
    }
  }

  Future<List<PostModel>> getChannelPosts(
    String channelId, {
    int limit = 60,
    String? before,
  }) async {
    try {
      final entries = await _dao.getChannelPosts(
        channelId,
        limit: limit,
        before: before,
      );
      return entries.map(PostMapper.fromEntry).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get cached posts: $e');
    }
  }

  Future<PostModel?> getPost(String id) async {
    try {
      final entry = await _dao.getPost(id);
      if (entry == null) return null;
      return PostMapper.fromEntry(entry);
    } catch (e) {
      throw CacheException(message: 'Failed to get cached post: $e');
    }
  }

  Future<void> deletePost(String id) async {
    try {
      await _dao.deletePost(id);
    } catch (e) {
      throw CacheException(message: 'Failed to delete cached post: $e');
    }
  }

  Future<void> savePendingPost(Post post) async {
    try {
      final companion = PostMapper.toCompanion(
        post,
        isPending: true,
        sendStatus: 1,
      );
      await _dao.upsertPosts([companion]);
    } catch (e) {
      throw CacheException(message: 'Failed to save pending post: $e');
    }
  }

  Future<List<PostModel>> getPendingPosts() async {
    try {
      final entries = await _dao.getPendingPosts();
      return entries.map(PostMapper.fromEntry).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get pending posts: $e');
    }
  }

  Future<void> markAsSent(String id) async {
    try {
      await _dao.markAsSent(id);
    } catch (e) {
      throw CacheException(message: 'Failed to mark post as sent: $e');
    }
  }

  Future<void> markAsFailed(String id) async {
    try {
      await _dao.markAsFailed(id);
    } catch (e) {
      throw CacheException(message: 'Failed to mark post as failed: $e');
    }
  }
}
