import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/server_account.dart';
import '../../domain/repositories/server_account_repository.dart';
import '../config/app_config.dart';
import 'secure_storage.dart';

class ServerAccountMigration {
  static const _migrationDoneKey = 'server_accounts_migrated';

  final ServerAccountRepository _repository;
  final SecureStorage _secureStorage;

  ServerAccountMigration({
    required ServerAccountRepository repository,
    required SecureStorage secureStorage,
  })  : _repository = repository,
        _secureStorage = secureStorage;

  Future<void> migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationDoneKey) == true) return;

    final hasToken = await _secureStorage.hasLegacyToken();
    if (!hasToken) {
      await prefs.setBool(_migrationDoneKey, true);
      return;
    }

    final userId = await _secureStorage.getUserId() ?? '';
    final now = DateTime.now();
    final accountId = now.microsecondsSinceEpoch.toRadixString(36);

    final account = ServerAccount(
      id: accountId,
      serverUrl: AppConfig.serverUrl,
      displayName: _extractDisplayName(AppConfig.serverUrl),
      userId: userId,
      addedAt: now,
      lastActiveAt: now,
    );

    await _repository.add(account);
    await _repository.setActive(accountId);
    await _secureStorage.migrateLegacyToAccount(accountId);
    await _migrateSharedPrefsKeys(prefs, accountId);
    await prefs.setBool(_migrationDoneKey, true);
  }

  /// Migrate legacy SharedPreferences keys to per-account format.
  Future<void> _migrateSharedPrefsKeys(
    SharedPreferences prefs,
    String accountId,
  ) async {
    // drafts → drafts_{accountId}
    final drafts = prefs.getString('drafts');
    if (drafts != null) {
      await prefs.setString('drafts_$accountId', drafts);
      await prefs.remove('drafts');
    }

    // selected_team_id → selected_team_id_{accountId}
    final teamId = prefs.getString('selected_team_id');
    if (teamId != null) {
      await prefs.setString('selected_team_id_$accountId', teamId);
      await prefs.remove('selected_team_id');
    }

    // recent_emojis → recent_emojis_{accountId}
    final recentEmojis = prefs.getStringList('recent_emojis');
    if (recentEmojis != null) {
      await prefs.setStringList('recent_emojis_$accountId', recentEmojis);
      await prefs.remove('recent_emojis');
    }

    // channel_notification_{channelId} → channel_notification_{accountId}_{channelId}
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith('channel_notification_')) {
        final channelId = key.substring('channel_notification_'.length);
        final value = prefs.getString(key);
        if (value != null) {
          await prefs.setString(
            'channel_notification_${accountId}_$channelId',
            value,
          );
          await prefs.remove(key);
        }
      }
    }
  }

  static String _extractDisplayName(String serverUrl) {
    try {
      final uri = Uri.parse(serverUrl);
      return uri.host;
    } catch (_) {
      return serverUrl;
    }
  }
}
