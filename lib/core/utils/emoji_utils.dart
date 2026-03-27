import 'emoji_map.dart';

final _emojiRegex = RegExp(r':([a-zA-Z0-9_+\-]+):');
final _codeBlockRegex = RegExp(r'(```[\s\S]*?```|`[^`]+`)');

const _maxCacheSize = 256;
final _emojiCache = <String, String>{};

/// Replaces :emoji_code: with Unicode characters (system emojis)
/// or markdown images (custom server emojis).
/// Skips codes inside `inline code` and ```code blocks```.
/// Results are cached (LRU, up to [_maxCacheSize] entries).
String replaceEmojis(
  String text, {
  Map<String, String> customEmojiUrls = const {},
}) {
  if (!text.contains(':')) return text;

  final cached = _emojiCache[text];
  if (cached != null) {
    // Move to end (most recently used)
    _emojiCache.remove(text);
    _emojiCache[text] = cached;
    return cached;
  }

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

  final result = text.replaceAllMapped(_emojiRegex, (match) {
    if (isInsideCode(match.start)) return match.group(0)!;

    final code = match.group(1)!;

    final unicode = emojiMap[code];
    if (unicode != null) return unicode;

    final customUrl = customEmojiUrls[code];
    if (customUrl != null) return '![emoji]($customUrl)';

    return match.group(0)!;
  });

  // Evict oldest if at capacity
  if (_emojiCache.length >= _maxCacheSize) {
    _emojiCache.remove(_emojiCache.keys.first);
  }
  _emojiCache[text] = result;

  return result;
}
