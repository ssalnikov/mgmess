import 'package:mgmess/core/storage/secure_storage.dart';

/// In-memory SecureStorage для интеграционных тестов.
/// Обходит FlutterSecureStorage, хранит данные в Map.
class FakeSecureStorage extends SecureStorage {
  final Map<String, String> _data = {};

  FakeSecureStorage() : super();

  @override
  Future<void> saveToken(String token) async {
    _data['mm_auth_token'] = token;
  }

  @override
  Future<String?> getToken() async {
    return _data['mm_auth_token'];
  }

  @override
  Future<void> saveCsrfToken(String token) async {
    _data['mm_csrf_token'] = token;
  }

  @override
  Future<String?> getCsrfToken() async {
    return _data['mm_csrf_token'];
  }

  @override
  Future<void> saveUserId(String userId) async {
    _data['mm_user_id'] = userId;
  }

  @override
  Future<String?> getUserId() async {
    return _data['mm_user_id'];
  }

  @override
  Future<void> clearAll() async {
    _data.clear();
  }
}
