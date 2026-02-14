import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../models/user_model.dart';

class UserRemoteDataSource {
  final ApiClient _apiClient;

  UserRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<UserModel> getUser(String userId) async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.user(userId));
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to get user: $e');
    }
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.usersByIds,
        data: userIds,
      );
      return (response.data as List<dynamic>)
          .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get users by ids: $e');
    }
  }

  Future<UserModel> updateUser(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.userPatch(userId),
        data: patch,
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to update user: $e');
    }
  }

  Future<void> uploadUserImage(String userId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      await _apiClient.dio.post(
        ApiEndpoints.userImage(userId),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } catch (e) {
      throw ServerException(message: 'Failed to upload avatar: $e');
    }
  }

  Future<Map<String, String>> getUserStatuses(
    List<String> userIds,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.usersStatus,
        data: userIds,
      );
      final Map<String, String> statuses = {};
      for (final s in response.data as List<dynamic>) {
        final map = s as Map<String, dynamic>;
        statuses[map['user_id'] as String] = map['status'] as String;
      }
      return statuses;
    } catch (e) {
      throw ServerException(message: 'Failed to get user statuses: $e');
    }
  }
}
