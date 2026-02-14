import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../models/seen_list_model.dart';

class SeensRemoteDataSource {
  final ApiClient _apiClient;

  SeensRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<SeenListModel> getChannelSeens(String channelId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.channelSeens(channelId),
      );
      return SeenListModel.fromJson(
        response.data as Map<String, dynamic>,
        channelId: channelId,
      );
    } catch (e) {
      throw ServerException(
          message: 'Failed to get channel seens: $e');
    }
  }

  Future<SeenListModel> getPostSeens(String postId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.postSeens(postId),
      );
      return SeenListModel.fromJson(
        response.data as Map<String, dynamic>,
        postId: postId,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to get post seens: $e');
    }
  }
}
