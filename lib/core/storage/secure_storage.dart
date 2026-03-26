import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  // Legacy keys (used before multi-server support)
  static const _keyToken = 'mm_auth_token';
  static const _keyCsrf = 'mm_csrf_token';
  static const _keyUserId = 'mm_user_id';

  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  // --- Per-account methods ---

  Future<void> saveAccountToken(String accountId, String token) =>
      _storage.write(key: '${accountId}_auth_token', value: token);

  Future<String?> getAccountToken(String accountId) =>
      _storage.read(key: '${accountId}_auth_token');

  Future<void> saveAccountCsrfToken(String accountId, String token) =>
      _storage.write(key: '${accountId}_csrf_token', value: token);

  Future<String?> getAccountCsrfToken(String accountId) =>
      _storage.read(key: '${accountId}_csrf_token');

  Future<void> saveAccountUserId(String accountId, String userId) =>
      _storage.write(key: '${accountId}_user_id', value: userId);

  Future<String?> getAccountUserId(String accountId) =>
      _storage.read(key: '${accountId}_user_id');

  Future<void> clearAccount(String accountId) async {
    await _storage.delete(key: '${accountId}_auth_token');
    await _storage.delete(key: '${accountId}_csrf_token');
    await _storage.delete(key: '${accountId}_user_id');
  }

  // --- Legacy single-server methods (delegate to per-account) ---

  Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  Future<String?> getToken() => _storage.read(key: _keyToken);

  Future<void> saveCsrfToken(String token) =>
      _storage.write(key: _keyCsrf, value: token);

  Future<String?> getCsrfToken() => _storage.read(key: _keyCsrf);

  Future<void> saveUserId(String userId) =>
      _storage.write(key: _keyUserId, value: userId);

  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  Future<void> clearAll() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyCsrf);
    await _storage.delete(key: _keyUserId);
  }

  // --- Unified accessors (account-aware with legacy fallback) ---

  Future<String?> getTokenFor(String? accountId) =>
      accountId != null ? getAccountToken(accountId) : getToken();

  Future<String?> getCsrfFor(String? accountId) =>
      accountId != null ? getAccountCsrfToken(accountId) : getCsrfToken();

  Future<String?> getUserIdFor(String? accountId) =>
      accountId != null ? getAccountUserId(accountId) : getUserId();

  Future<void> saveTokenFor(String? accountId, String token) =>
      accountId != null ? saveAccountToken(accountId, token) : saveToken(token);

  Future<void> saveCsrfFor(String? accountId, String token) =>
      accountId != null
          ? saveAccountCsrfToken(accountId, token)
          : saveCsrfToken(token);

  Future<void> saveUserIdFor(String? accountId, String userId) =>
      accountId != null
          ? saveAccountUserId(accountId, userId)
          : saveUserId(userId);

  Future<void> clearFor(String? accountId) =>
      accountId != null ? clearAccount(accountId) : clearAll();

  // --- Migration helpers ---

  Future<bool> hasLegacyToken() async {
    final token = await _storage.read(key: _keyToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> migrateLegacyToAccount(String accountId) async {
    final token = await _storage.read(key: _keyToken);
    final csrf = await _storage.read(key: _keyCsrf);
    final userId = await _storage.read(key: _keyUserId);

    if (token != null) await saveAccountToken(accountId, token);
    if (csrf != null) await saveAccountCsrfToken(accountId, csrf);
    if (userId != null) await saveAccountUserId(accountId, userId);

    // Legacy keys kept — they are still used by existing code until Phase 2
  }
}
