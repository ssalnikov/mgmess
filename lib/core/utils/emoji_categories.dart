import 'emoji_map.dart';

class EmojiCategory {
  final String name;
  final String icon;
  final List<MapEntry<String, String>> emojis;

  const EmojiCategory({
    required this.name,
    required this.icon,
    required this.emojis,
  });
}

/// Cached categories — built once, reused across rebuilds.
List<EmojiCategory>? _cachedCategories;

List<EmojiCategory> getEmojiCategories() {
  return _cachedCategories ??= _buildCategories();
}

List<EmojiCategory> _buildCategories() {
  final entries = emojiMap.entries.toList();
  final categories = <EmojiCategory>[];

  // Each category defined by (name, icon, startKey)
  // endIndex is the startKey of the next category
  final defs = [
    ('Smileys', '\u{1F600}', 'grinning'),
    ('People', '\u{1F44B}', 'wave'),
    ('Animals', '\u{1F435}', 'monkey_face'),
    ('Food', '\u{1F347}', 'grapes'),
    ('Travel', '\u{1F30D}', 'earth_africa'),
    ('Activities', '\u{1F383}', 'jack_o_lantern'),
    ('Objects', '\u{1F453}', 'eyeglasses'),
    ('Symbols', '\u{1F3E7}', 'atm'),
    ('Flags', '\u{1F3C1}', 'checkered_flag'),
  ];

  for (var i = 0; i < defs.length; i++) {
    final (name, icon, startKey) = defs[i];
    final startIdx = entries.indexWhere((e) => e.key == startKey);
    if (startIdx == -1) continue;

    final endIdx = i + 1 < defs.length
        ? entries.indexWhere((e) => e.key == defs[i + 1].$3)
        : entries.length;

    final effectiveEnd = endIdx == -1 ? entries.length : endIdx;

    if (startIdx < effectiveEnd) {
      categories.add(EmojiCategory(
        name: name,
        icon: icon,
        emojis: entries.sublist(startIdx, effectiveEnd),
      ));
    }
  }

  if (categories.isEmpty) {
    categories.add(EmojiCategory(
      name: 'All',
      icon: '\u{1F600}',
      emojis: entries,
    ));
  }

  return categories;
}
