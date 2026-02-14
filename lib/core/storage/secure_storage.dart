import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _keyToken = 'mm_auth_token';
  static const _keyCsrf = 'mm_csrf_token';
  static const _keyUserId = 'mm_user_id';

  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  Future<String?> getToken() => _storage.read(key: _keyToken);

  Future<void> saveCsrfToken(String token) =>
      _storage.write(key: _keyCsrf, value: token);

  Future<String?> getCsrfToken() => _storage.read(key: _keyCsrf);

  Future<void> saveUserId(String userId) =>
      _storage.write(key: _keyUserId, value: userId);

  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  Future<void> clearAll() => _storage.deleteAll();
}
