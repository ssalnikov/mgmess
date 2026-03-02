import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../models/custom_emoji_model.dart';

class EmojiRemoteDataSource {
  final ApiClient _apiClient;

  EmojiRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// Loads all custom emojis from the server (paginated, 200 per page).
  Future<List<CustomEmojiModel>> getCustomEmojis() async {
    try {
      final allEmojis = <CustomEmojiModel>[];
      var page = 0;
      const perPage = 200;

      while (true) {
        final response = await _apiClient.dio.get(
          ApiEndpoints.customEmojis,
          queryParameters: {'page': page, 'per_page': perPage},
        );
        final list = (response.data as List)
            .map((e) => CustomEmojiModel.fromJson(e as Map<String, dynamic>))
            .toList();
        allEmojis.addAll(list);
        if (list.length < perPage) break;
        page++;
      }

      return allEmojis;
    } catch (e) {
      throw ServerException(message: 'Failed to get custom emojis: $e');
    }
  }
}
