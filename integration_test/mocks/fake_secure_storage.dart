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
    _data.remove('mm_auth_token');
    _data.remove('mm_csrf_token');
    _data.remove('mm_user_id');
  }

  // --- Per-account methods ---

  @override
  Future<void> saveAccountToken(String accountId, String token) async {
    _data['${accountId}_auth_token'] = token;
  }

  @override
  Future<String?> getAccountToken(String accountId) async {
    return _data['${accountId}_auth_token'];
  }

  @override
  Future<void> saveAccountCsrfToken(String accountId, String token) async {
    _data['${accountId}_csrf_token'] = token;
  }

  @override
  Future<String?> getAccountCsrfToken(String accountId) async {
    return _data['${accountId}_csrf_token'];
  }

  @override
  Future<void> saveAccountUserId(String accountId, String userId) async {
    _data['${accountId}_user_id'] = userId;
  }

  @override
  Future<String?> getAccountUserId(String accountId) async {
    return _data['${accountId}_user_id'];
  }

  @override
  Future<void> clearAccount(String accountId) async {
    _data.remove('${accountId}_auth_token');
    _data.remove('${accountId}_csrf_token');
    _data.remove('${accountId}_user_id');
  }

  @override
  Future<bool> hasLegacyToken() async {
    final token = _data['mm_auth_token'];
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> migrateLegacyToAccount(String accountId) async {
    final token = _data['mm_auth_token'];
    final csrf = _data['mm_csrf_token'];
    final userId = _data['mm_user_id'];

    if (token != null) await saveAccountToken(accountId, token);
    if (csrf != null) await saveAccountCsrfToken(accountId, csrf);
    if (userId != null) await saveAccountUserId(accountId, userId);
  }
}
