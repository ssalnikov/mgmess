import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../models/post_model.dart';
import '../../models/user_thread_model.dart';

class PostRemoteDataSource {
  final ApiClient _apiClient;

  PostRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<PostModel>> getChannelPosts(
    String channelId, {
    int page = 0,
    int perPage = 60,
    String? before,
    String? after,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (before != null) queryParams['before'] = before;
      if (after != null) queryParams['after'] = after;

      final response = await _apiClient.dio.get(
        ApiEndpoints.channelPosts(channelId),
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      final posts = data['posts'] as Map<String, dynamic>? ?? {};
      final order = (data['order'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];

      return order
          .where((id) => posts.containsKey(id))
          .map((id) =>
              PostModel.fromJson(posts[id] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get posts: $e');
    }
  }

  Future<PostModel> createPost({
    required String channelId,
    required String message,
    String? rootId,
    List<String>? fileIds,
  }) async {
    try {
      final body = <String, dynamic>{
        'channel_id': channelId,
        'message': message,
      };
      if (rootId != null && rootId.isNotEmpty) body['root_id'] = rootId;
      if (fileIds != null && fileIds.isNotEmpty) {
        body['file_ids'] = fileIds;
      }

      final response = await _apiClient.dio.post(
        '/posts',
        data: body,
      );
      return PostModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to create post: $e');
    }
  }

  Future<PostModel> getPost(String postId) async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.post(postId));
      return PostModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to get post: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _apiClient.dio.delete(ApiEndpoints.post(postId));
    } catch (e) {
      throw ServerException(message: 'Failed to delete post: $e');
    }
  }

  Future<List<PostModel>> getPostThread(String postId) async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.postThread(postId));
      final data = response.data as Map<String, dynamic>;
      final posts = data['posts'] as Map<String, dynamic>? ?? {};
      final order = (data['order'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];
      return order
          .where((id) => posts.containsKey(id))
          .map((id) =>
              PostModel.fromJson(posts[id] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get post thread: $e');
    }
  }

  Future<List<PostModel>> getFlaggedPosts(
    String userId, {
    int page = 0,
    int perPage = 60,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.flaggedPosts(userId),
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final data = response.data as Map<String, dynamic>;
      final posts = data['posts'] as Map<String, dynamic>? ?? {};
      final order = (data['order'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];
      return order
          .where((id) => posts.containsKey(id))
          .map((id) =>
              PostModel.fromJson(posts[id] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get flagged posts: $e');
    }
  }

  Future<List<PostModel>> searchPosts(
    String teamId,
    String terms,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.teamPostsSearch(teamId),
        data: {
          'terms': terms,
          'is_or_search': false,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final posts = data['posts'] as Map<String, dynamic>? ?? {};
      final order = (data['order'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];
      return order
          .where((id) => posts.containsKey(id))
          .map((id) =>
              PostModel.fromJson(posts[id] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to search posts: $e');
    }
  }

  Future<void> flagPost(String userId, String postId) async {
    try {
      await _apiClient.dio.put(
        ApiEndpoints.preferences(userId),
        data: [
          {
            'user_id': userId,
            'category': 'flagged_post',
            'name': postId,
            'value': 'true',
          }
        ],
      );
    } catch (e) {
      throw ServerException(message: 'Failed to flag post: $e');
    }
  }

  Future<List<UserThreadModel>> getUserThreads(
    String userId,
    String teamId, {
    int perPage = 25,
    String? before,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'per_page': perPage,
        'extended': true,
      };
      if (before != null) queryParams['before'] = before;

      final response = await _apiClient.dio.get(
        ApiEndpoints.userThreads(userId, teamId),
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      final threads = data['threads'] as List<dynamic>? ?? [];
      return threads
          .map((t) => UserThreadModel.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get user threads: $e');
    }
  }

  Future<void> unflagPost(String userId, String postId) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.preferencesDelete(userId),
        data: [
          {
            'user_id': userId,
            'category': 'flagged_post',
            'name': postId,
          }
        ],
      );
    } catch (e) {
      throw ServerException(message: 'Failed to unflag post: $e');
    }
  }
}
