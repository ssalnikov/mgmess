import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/data/models/custom_emoji_model.dart';

void main() {
  group('CustomEmojiModel', () {
    const json = {
      'id': 'emoji123',
      'name': 'party_parrot',
      'creator_id': 'user456',
    };

    test('fromJson creates correct model', () {
      final emoji = CustomEmojiModel.fromJson(json);
      expect(emoji.id, 'emoji123');
      expect(emoji.name, 'party_parrot');
      expect(emoji.creatorId, 'user456');
    });

    test('fromJson handles missing fields', () {
      final emoji = CustomEmojiModel.fromJson({});
      expect(emoji.id, '');
      expect(emoji.name, '');
      expect(emoji.creatorId, '');
    });

    test('fromJson handles partial fields', () {
      final emoji = CustomEmojiModel.fromJson({
        'id': 'abc',
        'name': 'test_emoji',
      });
      expect(emoji.id, 'abc');
      expect(emoji.name, 'test_emoji');
      expect(emoji.creatorId, '');
    });

    test('fromJson handles null values', () {
      final emoji = CustomEmojiModel.fromJson({
        'id': null,
        'name': null,
        'creator_id': null,
      });
      expect(emoji.id, '');
      expect(emoji.name, '');
      expect(emoji.creatorId, '');
    });
  });
}
