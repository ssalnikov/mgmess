import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/core/utils/emoji_utils.dart';

void main() {
  group('replaceEmojis', () {
    group('system emojis', () {
      test('replaces single emoji shortcode with Unicode', () {
        expect(replaceEmojis(':smile:'), '\u{1F604}');
      });

      test('replaces multiple emojis in text', () {
        final result = replaceEmojis('Hello :smile: :+1: :heart:');
        expect(result, 'Hello \u{1F604} \u{1F44D} \u{2764}\u{FE0F}');
      });

      test('replaces emoji at start of text', () {
        expect(replaceEmojis(':fire: hot!'), '\u{1F525} hot!');
      });

      test('replaces emoji at end of text', () {
        expect(replaceEmojis('done :white_check_mark:'), 'done \u{2705}');
      });

      test('replaces adjacent emojis', () {
        final result = replaceEmojis(':smile::heart:');
        expect(result, '\u{1F604}\u{2764}\u{FE0F}');
      });

      test('handles emoji with hyphens', () {
        expect(replaceEmojis(':+1:'), '\u{1F44D}');
        expect(replaceEmojis(':-1:'), '\u{1F44E}');
      });

      test('handles emoji with underscores', () {
        expect(
          replaceEmojis(':slightly_smiling_face:'),
          '\u{1F642}',
        );
      });
    });

    group('unknown emojis', () {
      test('preserves unknown shortcode as-is', () {
        expect(replaceEmojis(':nonexistent_emoji:'), ':nonexistent_emoji:');
      });

      test('preserves mixed known and unknown', () {
        final result = replaceEmojis(':smile: :fakemoji:');
        expect(result, '\u{1F604} :fakemoji:');
      });
    });

    group('custom emojis', () {
      test('replaces custom emoji with markdown image', () {
        final result = replaceEmojis(
          ':company_logo:',
          customEmojiUrls: {
            'company_logo': 'https://mm.my.games/api/v4/emoji/abc123/image',
          },
        );
        expect(
          result,
          '![emoji](https://mm.my.games/api/v4/emoji/abc123/image)',
        );
      });

      test('system emoji takes priority over custom', () {
        final result = replaceEmojis(
          ':smile:',
          customEmojiUrls: {
            'smile': 'https://example.com/smile.png',
          },
        );
        expect(result, '\u{1F604}');
      });

      test('custom emoji mixed with system', () {
        final result = replaceEmojis(
          ':smile: :custom_one: :heart:',
          customEmojiUrls: {
            'custom_one': 'https://example.com/emoji/custom/image',
          },
        );
        expect(
          result,
          '\u{1F604} ![emoji](https://example.com/emoji/custom/image) \u{2764}\u{FE0F}',
        );
      });
    });

    group('code block protection', () {
      test('does not replace emoji inside inline code', () {
        expect(replaceEmojis('use `:smile:` for smile'), 'use `:smile:` for smile');
      });

      test('does not replace emoji inside fenced code block', () {
        final text = '```\n:smile:\n```';
        expect(replaceEmojis(text), text);
      });

      test('replaces emoji outside code but not inside', () {
        final result = replaceEmojis(':heart: and `:smile:` here');
        expect(result, '\u{2764}\u{FE0F} and `:smile:` here');
      });

      test('handles multiple code spans', () {
        final result =
            replaceEmojis('`:a:` :smile: `:b:` :heart:');
        expect(result, '`:a:` \u{1F604} `:b:` \u{2764}\u{FE0F}');
      });

      test('does not replace emoji inside fenced code block with language', () {
        final text = '```dart\nString s = ":smile:";\n```';
        expect(replaceEmojis(text), text);
      });
    });

    group('edge cases', () {
      test('returns empty string for empty input', () {
        expect(replaceEmojis(''), '');
      });

      test('returns text without colons unchanged', () {
        expect(replaceEmojis('Hello world'), 'Hello world');
      });

      test('single colon does not trigger replacement', () {
        expect(replaceEmojis('time: 12:30'), 'time: 12:30');
      });

      test('incomplete shortcode is not replaced', () {
        expect(replaceEmojis(':smile'), ':smile');
      });

      test('empty shortcode is not replaced', () {
        expect(replaceEmojis('::'), '::');
      });

      test('preserves surrounding text', () {
        final result = replaceEmojis('before :smile: after');
        expect(result, 'before \u{1F604} after');
      });

      test('handles text with URLs containing colons', () {
        const text = 'visit https://example.com:8080/path';
        expect(replaceEmojis(text), text);
      });

      test('handles multiline text', () {
        final result = replaceEmojis('line1 :smile:\nline2 :heart:');
        expect(result, 'line1 \u{1F604}\nline2 \u{2764}\u{FE0F}');
      });
    });
  });
}
