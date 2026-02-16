import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<void> registerDeviceToken(String token) async {
    try {
      await _apiClient.dio.put(
        ApiEndpoints.deviceId,
        data: {'device_id': 'android:$token'},
      );
    } catch (e) {
      throw ServerException(message: 'Failed to register device token: $e');
    }
  }

  Future<void> unregisterDevice() async {
    try {
      await _apiClient.dio.put(
        ApiEndpoints.deviceId,
        data: {'device_id': ''},
      );
    } catch (e) {
      throw ServerException(message: 'Failed to unregister device: $e');
    }
  }
}
