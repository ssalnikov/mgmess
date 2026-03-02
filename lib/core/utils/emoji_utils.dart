import 'emoji_map.dart';

final _emojiRegex = RegExp(r':([a-zA-Z0-9_+\-]+):');
final _codeBlockRegex = RegExp(r'(```[\s\S]*?```|`[^`]+`)');

/// Replaces :emoji_code: with Unicode characters (system emojis)
/// or markdown images (custom server emojis).
/// Skips codes inside `inline code` and ```code blocks```.
String replaceEmojis(
  String text, {
  Map<String, String> customEmojiUrls = const {},
}) {
  if (!text.contains(':')) return text;

  final codeSpans = <({int start, int end})>[];
  for (final match in _codeBlockRegex.allMatches(text)) {
    codeSpans.add((start: match.start, end: match.end));
  }

  bool isInsideCode(int position) {
    for (final span in codeSpans) {
      if (position >= span.start && position < span.end) return true;
    }
    return false;
  }

  return text.replaceAllMapped(_emojiRegex, (match) {
    if (isInsideCode(match.start)) return match.group(0)!;

    final code = match.group(1)!;

    final unicode = emojiMap[code];
    if (unicode != null) return unicode;

    final customUrl = customEmojiUrls[code];
    if (customUrl != null) return '![emoji]($customUrl)';

    return match.group(0)!;
  });
}
