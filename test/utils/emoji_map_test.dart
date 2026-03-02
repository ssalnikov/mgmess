import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/core/utils/emoji_map.dart';

void main() {
  group('emojiMap', () {
    test('contains all emojis from original _emojiMap (33 entries)', () {
      // These were the original hardcoded entries in message_bubble.dart.
      // All must be present with the same Unicode values.
      expect(emojiMap['+1'], '\u{1F44D}');
      expect(emojiMap['heart'], '\u{2764}\u{FE0F}');
      expect(emojiMap['grinning'], '\u{1F600}');
      expect(emojiMap['white_check_mark'], '\u{2705}');
      expect(emojiMap['eyes'], '\u{1F440}');
      expect(emojiMap['raised_hands'], '\u{1F64C}');
      expect(emojiMap['thumbsup'], '\u{1F44D}');
      expect(emojiMap['thumbsdown'], '\u{1F44E}');
      expect(emojiMap['smile'], '\u{1F604}');
      expect(emojiMap['laughing'], '\u{1F606}');
      expect(emojiMap['blush'], '\u{1F60A}');
      expect(emojiMap['slightly_smiling_face'], '\u{1F642}');
      expect(emojiMap['wink'], '\u{1F609}');
      expect(emojiMap['joy'], '\u{1F602}');
      expect(emojiMap['tada'], '\u{1F389}');
      expect(emojiMap['clap'], '\u{1F44F}');
      expect(emojiMap['fire'], '\u{1F525}');
      expect(emojiMap['rocket'], '\u{1F680}');
      expect(emojiMap['thinking'], '\u{1F914}');
      expect(emojiMap['pray'], '\u{1F64F}');
      expect(emojiMap['sob'], '\u{1F62D}');
      expect(emojiMap['angry'], '\u{1F620}');
      expect(emojiMap['confused'], '\u{1F615}');
      expect(emojiMap['ok_hand'], '\u{1F44C}');
      expect(emojiMap['wave'], '\u{1F44B}');
      expect(emojiMap['muscle'], '\u{1F4AA}');
      expect(emojiMap['100'], '\u{1F4AF}');
      expect(emojiMap['star'], '\u{2B50}');
      expect(emojiMap['warning'], '\u{26A0}\u{FE0F}');
      expect(emojiMap['x'], '\u{274C}');
      expect(emojiMap['heavy_check_mark'], '\u{2714}\u{FE0F}');
      expect(emojiMap['-1'], '\u{1F44E}');
    });

    test('contains common Mattermost emojis', () {
      // Essential emojis that Mattermost users commonly use
      expect(emojiMap.containsKey('sunglasses'), true);
      expect(emojiMap.containsKey('heart_eyes'), true);
      expect(emojiMap.containsKey('poop'), true);
      expect(emojiMap.containsKey('skull'), true);
      expect(emojiMap.containsKey('dog'), true);
      expect(emojiMap.containsKey('cat'), true);
      expect(emojiMap.containsKey('pizza'), true);
      expect(emojiMap.containsKey('coffee'), true);
      expect(emojiMap.containsKey('beer'), true);
      expect(emojiMap.containsKey('trophy'), true);
    });

    test('has at least 500 entries', () {
      expect(emojiMap.length, greaterThan(500));
    });

    test('all values are non-empty strings', () {
      for (final entry in emojiMap.entries) {
        expect(entry.value.isNotEmpty, true,
            reason: 'Empty value for key "${entry.key}"');
      }
    });

    test('all keys are non-empty lowercase with valid characters', () {
      final validKeyPattern = RegExp(r'^[a-z0-9_+\-]+$');
      for (final key in emojiMap.keys) {
        expect(key.isNotEmpty, true, reason: 'Empty key found');
        expect(validKeyPattern.hasMatch(key), true,
            reason: 'Invalid key format: "$key"');
      }
    });

    test('aliases map to the same Unicode as their canonical form', () {
      // +1 and thumbsup should be the same
      expect(emojiMap['+1'], emojiMap['thumbsup']);
      // -1 and thumbsdown should be the same
      expect(emojiMap['-1'], emojiMap['thumbsdown']);
    });
  });
}
