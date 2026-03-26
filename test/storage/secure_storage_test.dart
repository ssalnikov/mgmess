import 'package:flutter_test/flutter_test.dart';
import '../../integration_test/mocks/fake_secure_storage.dart';

void main() {
  late FakeSecureStorage storage;

  setUp(() {
    storage = FakeSecureStorage();
  });

  group('SecureStorage per-account methods', () {
    test('saveAccountToken and getAccountToken', () async {
      await storage.saveAccountToken('acc1', 'token123');
      expect(await storage.getAccountToken('acc1'), 'token123');
      expect(await storage.getAccountToken('acc2'), isNull);
    });

    test('saveAccountCsrfToken and getAccountCsrfToken', () async {
      await storage.saveAccountCsrfToken('acc1', 'csrf456');
      expect(await storage.getAccountCsrfToken('acc1'), 'csrf456');
    });

    test('saveAccountUserId and getAccountUserId', () async {
      await storage.saveAccountUserId('acc1', 'user789');
      expect(await storage.getAccountUserId('acc1'), 'user789');
    });

    test('clearAccount removes only that account data', () async {
      await storage.saveAccountToken('acc1', 'token1');
      await storage.saveAccountCsrfToken('acc1', 'csrf1');
      await storage.saveAccountUserId('acc1', 'user1');
      await storage.saveAccountToken('acc2', 'token2');

      await storage.clearAccount('acc1');

      expect(await storage.getAccountToken('acc1'), isNull);
      expect(await storage.getAccountCsrfToken('acc1'), isNull);
      expect(await storage.getAccountUserId('acc1'), isNull);
      expect(await storage.getAccountToken('acc2'), 'token2');
    });

    test('per-account keys are isolated from legacy keys', () async {
      await storage.saveToken('legacy_token');
      await storage.saveAccountToken('acc1', 'account_token');

      expect(await storage.getToken(), 'legacy_token');
      expect(await storage.getAccountToken('acc1'), 'account_token');
    });
  });

  group('SecureStorage migration', () {
    test('hasLegacyToken returns false when no token', () async {
      expect(await storage.hasLegacyToken(), false);
    });

    test('hasLegacyToken returns true when token exists', () async {
      await storage.saveToken('some_token');
      expect(await storage.hasLegacyToken(), true);
    });

    test('migrateLegacyToAccount copies all legacy data', () async {
      await storage.saveToken('tok');
      await storage.saveCsrfToken('csrf');
      await storage.saveUserId('uid');

      await storage.migrateLegacyToAccount('acc1');

      expect(await storage.getAccountToken('acc1'), 'tok');
      expect(await storage.getAccountCsrfToken('acc1'), 'csrf');
      expect(await storage.getAccountUserId('acc1'), 'uid');

      // Legacy keys preserved
      expect(await storage.getToken(), 'tok');
    });

    test('migrateLegacyToAccount handles partial data', () async {
      await storage.saveToken('tok');
      // No csrf, no userId

      await storage.migrateLegacyToAccount('acc1');

      expect(await storage.getAccountToken('acc1'), 'tok');
      expect(await storage.getAccountCsrfToken('acc1'), isNull);
      expect(await storage.getAccountUserId('acc1'), isNull);
    });
  });
}
