import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    const json = {
      'id': 'user123',
      'username': 'johndoe',
      'email': 'john@example.com',
      'first_name': 'John',
      'last_name': 'Doe',
      'nickname': 'JD',
      'position': 'Developer',
      'locale': 'en',
      'create_at': 1000000,
      'update_at': 2000000,
      'delete_at': 0,
    };

    test('fromJson creates correct model', () {
      final user = UserModel.fromJson(json);
      expect(user.id, 'user123');
      expect(user.username, 'johndoe');
      expect(user.email, 'john@example.com');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.nickname, 'JD');
      expect(user.position, 'Developer');
    });

    test('displayName returns full name when available', () {
      final user = UserModel.fromJson(json);
      expect(user.displayName, 'John Doe');
    });

    test('displayName returns nickname when no names', () {
      final user = UserModel.fromJson({
        ...json,
        'first_name': '',
        'last_name': '',
      });
      expect(user.displayName, 'JD');
    });

    test('displayName returns username as fallback', () {
      final user = UserModel.fromJson({
        ...json,
        'first_name': '',
        'last_name': '',
        'nickname': '',
      });
      expect(user.displayName, 'johndoe');
    });

    test('isDeleted returns true when delete_at > 0', () {
      final user = UserModel.fromJson({...json, 'delete_at': 100});
      expect(user.isDeleted, true);
    });

    test('isDeleted returns false when delete_at is 0', () {
      final user = UserModel.fromJson(json);
      expect(user.isDeleted, false);
    });

    test('toJson returns correct map', () {
      final user = UserModel.fromJson(json);
      final result = user.toJson();
      expect(result['id'], 'user123');
      expect(result['username'], 'johndoe');
      expect(result['email'], 'john@example.com');
    });

    test('fromJson handles missing fields gracefully', () {
      final user = UserModel.fromJson({'id': 'x', 'username': 'y'});
      expect(user.id, 'x');
      expect(user.email, '');
      expect(user.firstName, '');
    });

    test('fromJson handles completely empty map', () {
      final user = UserModel.fromJson({});
      expect(user.id, '');
      expect(user.username, '');
    });
  });
}
