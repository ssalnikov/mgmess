import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mgmess/data/repositories/server_account_repository_impl.dart';
import 'package:mgmess/domain/entities/server_account.dart';

void main() {
  late ServerAccountRepositoryImpl repository;

  final now = DateTime(2026, 3, 25, 12, 0, 0);

  final account1 = ServerAccount(
    id: 'acc1',
    serverUrl: 'https://server1.com',
    displayName: 'Server 1',
    userId: 'u1',
    username: 'user1',
    addedAt: now,
    lastActiveAt: now,
  );

  final account2 = ServerAccount(
    id: 'acc2',
    serverUrl: 'https://server2.com',
    displayName: 'Server 2',
    userId: 'u2',
    username: 'user2',
    addedAt: now,
    lastActiveAt: now,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = ServerAccountRepositoryImpl();
  });

  group('ServerAccountRepositoryImpl', () {
    test('getAll returns empty list initially', () async {
      final result = await repository.getAll();
      expect(result, isEmpty);
    });

    test('add and getAll', () async {
      await repository.add(account1);
      await repository.add(account2);

      final result = await repository.getAll();
      expect(result.length, 2);
      expect(result[0].id, 'acc1');
      expect(result[1].id, 'acc2');
    });

    test('setActive and getActive', () async {
      await repository.add(account1);
      await repository.add(account2);
      await repository.setActive('acc2');

      final active = await repository.getActive();
      expect(active, isNotNull);
      expect(active!.id, 'acc2');
    });

    test('getActive returns null when no accounts', () async {
      final active = await repository.getActive();
      expect(active, isNull);
    });

    test('getActive returns first account when active id not found', () async {
      await repository.add(account1);
      await repository.setActive('nonexistent');

      final active = await repository.getActive();
      expect(active, isNotNull);
      expect(active!.id, 'acc1');
    });

    test('remove deletes account', () async {
      await repository.add(account1);
      await repository.add(account2);
      await repository.remove('acc1');

      final result = await repository.getAll();
      expect(result.length, 1);
      expect(result[0].id, 'acc2');
    });

    test('remove active account switches to first remaining', () async {
      await repository.add(account1);
      await repository.add(account2);
      await repository.setActive('acc1');
      await repository.remove('acc1');

      final active = await repository.getActive();
      expect(active, isNotNull);
      expect(active!.id, 'acc2');
    });

    test('remove last account clears active', () async {
      await repository.add(account1);
      await repository.setActive('acc1');
      await repository.remove('acc1');

      final active = await repository.getActive();
      expect(active, isNull);
    });

    test('update modifies existing account', () async {
      await repository.add(account1);

      final updated = account1.copyWith(displayName: 'Updated Name');
      await repository.update(updated);

      final result = await repository.getAll();
      expect(result[0].displayName, 'Updated Name');
    });

    test('update ignores non-existent account', () async {
      await repository.add(account1);
      await repository.update(account2);

      final result = await repository.getAll();
      expect(result.length, 1);
      expect(result[0].id, 'acc1');
    });
  });
}
