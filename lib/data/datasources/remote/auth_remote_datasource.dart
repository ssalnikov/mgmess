import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.usersMe);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to get current user: $e');
    }
  }

  Future<(UserModel, String)> login({
    required String loginId,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.usersLogin,
        data: {'login_id': loginId, 'password': password},
      );
      final token = response.headers.value('Token');
      if (token == null || token.isEmpty) {
        throw const ServerException(message: 'No token in response');
      }
      final user = UserModel.fromJson(response.data as Map<String, dynamic>);
      return (user, token);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to login: $e');
    }
  }

  Future<Map<String, dynamic>> getClientConfig() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.clientConfig,
        queryParameters: {'format': 'old'},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw ServerException(message: 'Failed to get client config: $e');
    }
  }

  Future<List<TeamModel>> getMyTeams() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.teams);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => TeamModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get teams: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiEndpoints.usersLogout);
    } catch (e) {
      throw ServerException(message: 'Failed to logout: $e');
    }
  }
}
