import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/domain/entities/server_account.dart';

void main() {
  final now = DateTime(2026, 3, 25, 12, 0, 0);

  final account = ServerAccount(
    id: 'acc1',
    serverUrl: 'https://mm.corp.my.games',
    displayName: 'mm.corp.my.games',
    userId: 'user123',
    username: 'testuser',
    addedAt: now,
    lastActiveAt: now,
  );

  group('ServerAccount', () {
    test('toJson serializes all fields', () {
      final json = account.toJson();

      expect(json['id'], 'acc1');
      expect(json['serverUrl'], 'https://mm.corp.my.games');
      expect(json['displayName'], 'mm.corp.my.games');
      expect(json['userId'], 'user123');
      expect(json['username'], 'testuser');
      expect(json['addedAt'], now.toIso8601String());
      expect(json['lastActiveAt'], now.toIso8601String());
    });

    test('fromJson deserializes all fields', () {
      final json = account.toJson();
      final restored = ServerAccount.fromJson(json);

      expect(restored.id, 'acc1');
      expect(restored.serverUrl, 'https://mm.corp.my.games');
      expect(restored.displayName, 'mm.corp.my.games');
      expect(restored.userId, 'user123');
      expect(restored.username, 'testuser');
      expect(restored.addedAt, now);
      expect(restored.lastActiveAt, now);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'acc2',
        'serverUrl': 'https://example.com',
        'addedAt': now.toIso8601String(),
        'lastActiveAt': now.toIso8601String(),
      };
      final restored = ServerAccount.fromJson(json);

      expect(restored.displayName, '');
      expect(restored.userId, '');
      expect(restored.username, '');
    });

    test('roundtrip serialization preserves data', () {
      final json = account.toJson();
      final restored = ServerAccount.fromJson(json);
      final json2 = restored.toJson();

      expect(json, json2);
    });

    test('copyWith updates specified fields', () {
      final updated = account.copyWith(
        displayName: 'New Name',
        lastActiveAt: DateTime(2026, 4, 1),
      );

      expect(updated.id, 'acc1');
      expect(updated.serverUrl, 'https://mm.corp.my.games');
      expect(updated.displayName, 'New Name');
      expect(updated.lastActiveAt, DateTime(2026, 4, 1));
      expect(updated.userId, 'user123');
    });

    test('equality is based on id only', () {
      final account2 = ServerAccount(
        id: 'acc1',
        serverUrl: 'https://other.server',
        displayName: 'other',
        addedAt: DateTime(2020),
        lastActiveAt: DateTime(2020),
      );

      expect(account, equals(account2));
    });

    test('different ids are not equal', () {
      final account2 = ServerAccount(
        id: 'acc2',
        serverUrl: 'https://mm.corp.my.games',
        addedAt: now,
        lastActiveAt: now,
      );

      expect(account, isNot(equals(account2)));
    });
  });
}
