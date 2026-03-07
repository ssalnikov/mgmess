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

    group('custom status', () {
      test('fromJson parses customStatus from props as Map', () {
        final user = UserModel.fromJson({
          ...json,
          'props': {
            'customStatus': {
              'emoji': 'palm_tree',
              'text': 'On vacation',
            },
          },
        });
        expect(user.customStatusEmoji, 'palm_tree');
        expect(user.customStatusText, 'On vacation');
      });

      test('fromJson parses customStatus from props as JSON string', () {
        final user = UserModel.fromJson({
          ...json,
          'props': {
            'customStatus':
                '{"emoji":"coffee","text":"Having lunch"}',
          },
        });
        expect(user.customStatusEmoji, 'coffee');
        expect(user.customStatusText, 'Having lunch');
      });

      test('fromJson returns empty custom status when props missing', () {
        final user = UserModel.fromJson(json);
        expect(user.customStatusEmoji, '');
        expect(user.customStatusText, '');
      });

      test('fromJson returns empty custom status when props has no customStatus', () {
        final user = UserModel.fromJson({
          ...json,
          'props': {'some_other_key': 'value'},
        });
        expect(user.customStatusEmoji, '');
        expect(user.customStatusText, '');
      });

      test('fromJson handles empty customStatus string', () {
        final user = UserModel.fromJson({
          ...json,
          'props': {'customStatus': ''},
        });
        expect(user.customStatusEmoji, '');
        expect(user.customStatusText, '');
      });

      test('fromJson handles malformed customStatus JSON string', () {
        final user = UserModel.fromJson({
          ...json,
          'props': {'customStatus': 'not-json'},
        });
        expect(user.customStatusEmoji, '');
        expect(user.customStatusText, '');
      });

      test('fromJson handles customStatus with only emoji', () {
        final user = UserModel.fromJson({
          ...json,
          'props': {
            'customStatus': {'emoji': 'rocket'},
          },
        });
        expect(user.customStatusEmoji, 'rocket');
        expect(user.customStatusText, '');
      });

      test('fromJson handles customStatus with only text', () {
        final user = UserModel.fromJson({
          ...json,
          'props': {
            'customStatus': {'text': 'Busy'},
          },
        });
        expect(user.customStatusEmoji, '');
        expect(user.customStatusText, 'Busy');
      });

      test('fromJson ignores expired customStatus', () {
        final user = UserModel.fromJson({
          ...json,
          'props': {
            'customStatus': {
              'emoji': 'palm_tree',
              'text': 'On vacation',
              'expires_at': '2020-01-01T00:00:00Z',
            },
          },
        });
        expect(user.customStatusEmoji, '');
        expect(user.customStatusText, '');
      });

      test('fromJson keeps customStatus with no expiration', () {
        final user = UserModel.fromJson({
          ...json,
          'props': {
            'customStatus': {
              'emoji': 'rocket',
              'text': 'Working',
              'expires_at': '0001-01-01T00:00:00Z',
            },
          },
        });
        expect(user.customStatusEmoji, 'rocket');
        expect(user.customStatusText, 'Working');
      });

      test('fromJson keeps customStatus with future expiration', () {
        final user = UserModel.fromJson({
          ...json,
          'props': {
            'customStatus': {
              'emoji': 'coffee',
              'text': 'Break',
              'expires_at': '2099-12-31T23:59:59Z',
            },
          },
        });
        expect(user.customStatusEmoji, 'coffee');
        expect(user.customStatusText, 'Break');
      });

      test('fromJson keeps customStatus without expires_at', () {
        final user = UserModel.fromJson({
          ...json,
          'props': {
            'customStatus': {
              'emoji': 'wave',
              'text': 'Hello',
            },
          },
        });
        expect(user.customStatusEmoji, 'wave');
        expect(user.customStatusText, 'Hello');
      });
    });
  });
}
