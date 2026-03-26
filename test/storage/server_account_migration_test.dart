import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mgmess/core/config/app_config.dart';
import 'package:mgmess/core/storage/server_account_migration.dart';
import 'package:mgmess/data/repositories/server_account_repository_impl.dart';
import '../../integration_test/mocks/fake_secure_storage.dart';

void main() {
  late ServerAccountRepositoryImpl repository;
  late FakeSecureStorage secureStorage;
  late ServerAccountMigration migration;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = ServerAccountRepositoryImpl();
    secureStorage = FakeSecureStorage();
    migration = ServerAccountMigration(
      repository: repository,
      secureStorage: secureStorage,
    );
    AppConfig.serverUrlOverride = 'https://mm.corp.my.games';
  });

  group('ServerAccountMigration', () {
    test('creates account from legacy tokens', () async {
      await secureStorage.saveToken('test_token');
      await secureStorage.saveCsrfToken('test_csrf');
      await secureStorage.saveUserId('user123');

      await migration.migrateIfNeeded();

      final accounts = await repository.getAll();
      expect(accounts.length, 1);
      expect(accounts[0].serverUrl, 'https://mm.corp.my.games');
      expect(accounts[0].displayName, 'mm.corp.my.games');
      expect(accounts[0].userId, 'user123');

      final active = await repository.getActive();
      expect(active, isNotNull);
      expect(active!.id, accounts[0].id);

      // Tokens migrated to per-account keys
      expect(
        await secureStorage.getAccountToken(accounts[0].id),
        'test_token',
      );
      expect(
        await secureStorage.getAccountCsrfToken(accounts[0].id),
        'test_csrf',
      );
    });

    test('does nothing when no legacy token', () async {
      await migration.migrateIfNeeded();

      final accounts = await repository.getAll();
      expect(accounts, isEmpty);
    });

    test('does not run twice', () async {
      await secureStorage.saveToken('test_token');
      await secureStorage.saveUserId('user123');

      await migration.migrateIfNeeded();
      // Add a second token to verify migration doesn't run again
      await secureStorage.saveToken('another_token');
      await migration.migrateIfNeeded();

      final accounts = await repository.getAll();
      expect(accounts.length, 1);
    });

    test('handles missing userId gracefully', () async {
      await secureStorage.saveToken('test_token');

      await migration.migrateIfNeeded();

      final accounts = await repository.getAll();
      expect(accounts.length, 1);
      expect(accounts[0].userId, '');
    });

    test('migrates SharedPreferences keys to per-account format', () async {
      SharedPreferences.setMockInitialValues({
        'drafts': '{"ch1":"{\\"channelId\\":\\"ch1\\"}"}',
        'selected_team_id': 'team-001',
        'recent_emojis': ['smile', 'heart'],
        'channel_notification_ch1': 'mentions',
        'channel_notification_ch2': 'none',
      });
      repository = ServerAccountRepositoryImpl();
      migration = ServerAccountMigration(
        repository: repository,
        secureStorage: secureStorage,
      );
      await secureStorage.saveToken('test_token');

      await migration.migrateIfNeeded();

      final accounts = await repository.getAll();
      final accountId = accounts[0].id;
      final prefs = await SharedPreferences.getInstance();

      // Legacy keys removed
      expect(prefs.getString('drafts'), isNull);
      expect(prefs.getString('selected_team_id'), isNull);
      expect(prefs.getStringList('recent_emojis'), isNull);
      expect(prefs.getString('channel_notification_ch1'), isNull);
      expect(prefs.getString('channel_notification_ch2'), isNull);

      // Per-account keys created
      expect(prefs.getString('drafts_$accountId'), isNotNull);
      expect(prefs.getString('selected_team_id_$accountId'), 'team-001');
      expect(prefs.getStringList('recent_emojis_$accountId'), ['smile', 'heart']);
      expect(prefs.getString('channel_notification_${accountId}_ch1'), 'mentions');
      expect(prefs.getString('channel_notification_${accountId}_ch2'), 'none');
    });

    test('migration skips absent SharedPreferences keys', () async {
      SharedPreferences.setMockInitialValues({});
      repository = ServerAccountRepositoryImpl();
      migration = ServerAccountMigration(
        repository: repository,
        secureStorage: secureStorage,
      );
      await secureStorage.saveToken('test_token');

      await migration.migrateIfNeeded();

      final accounts = await repository.getAll();
      final accountId = accounts[0].id;
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getString('drafts_$accountId'), isNull);
      expect(prefs.getString('selected_team_id_$accountId'), isNull);
      expect(prefs.getStringList('recent_emojis_$accountId'), isNull);
    });
  });
}
