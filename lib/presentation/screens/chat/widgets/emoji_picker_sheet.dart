import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/custom_emoji_cache.dart';
import '../../../../core/utils/emoji_categories.dart';
import '../../../../core/utils/emoji_map.dart';

const _maxRecent = 32;

/// Full emoji picker with categories, search, recents, and custom server emojis.
class EmojiPickerSheet extends StatefulWidget {
  final void Function(String emojiName) onEmojiSelected;

  const EmojiPickerSheet({super.key, required this.onEmojiSelected});

  @override
  State<EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<EmojiPickerSheet>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _query = '';
  Map<String, String>? _authHeaders;
  late TabController _tabController;
  late List<EmojiCategory> _categories;
  List<String> _recentEmojis = [];
  bool _hasCustom = false;

  @override
  void initState() {
    super.initState();
    CustomEmojiCache.ensureLoaded();
    _categories = getEmojiCategories();
    _hasCustom = CustomEmojiCache.urls.isNotEmpty;

    // tabs: recent + custom(if any) + standard categories
    final tabCount = 1 + (_hasCustom ? 1 : 0) + _categories.length;
    _tabController = TabController(length: tabCount, vsync: this);
    _loadHeaders();
    _loadRecent();
  }

  Future<void> _loadHeaders() async {
    final token = await currentSession.getAuthToken();
    if (mounted) {
      setState(() {
        _authHeaders = {
          if (token != null) 'Authorization': 'Bearer $token',
        };
      });
    }
  }

  String get _recentKey => 'recent_emojis_${currentSession.accountId}';

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentEmojis = prefs.getStringList(_recentKey) ?? [];
      });
    }
  }

  Future<void> _saveRecent(String emojiName) async {
    _recentEmojis.remove(emojiName);
    _recentEmojis.insert(0, emojiName);
    if (_recentEmojis.length > _maxRecent) {
      _recentEmojis = _recentEmojis.sublist(0, _maxRecent);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, _recentEmojis);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSelect(String emojiName) {
    HapticFeedback.selectionClick();
    _saveRecent(emojiName);
    Navigator.pop(context);
    widget.onEmojiSelected(emojiName);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: context.l10n.searchEmoji,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            // Show search results OR tabbed categories
            if (_query.isNotEmpty)
              Expanded(child: _buildSearchResults(scrollController))
            else ...[
              // Category tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  const Tab(icon: Icon(Icons.access_time, size: 20)),
                  if (_hasCustom)
                    const Tab(icon: Icon(Icons.star, size: 20)),
                  ..._categories.map(
                    (c) => Tab(child: Text(c.icon, style: const TextStyle(fontSize: 20))),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGrid(_recentEmojis
                        .map((name) {
                          final unicode = emojiMap[name];
                          final url = CustomEmojiCache.getUrl(name);
                          return _EmojiEntry(name: name, unicode: unicode, imageUrl: url);
                        })
                        .toList()),
                    if (_hasCustom)
                      _buildGrid(CustomEmojiCache.urls.entries
                          .map((e) => _EmojiEntry(name: e.key, imageUrl: e.value))
                          .toList()),
                    ..._categories.map(
                      (cat) => _buildGrid(cat.emojis
                          .map((e) => _EmojiEntry(name: e.key, unicode: e.value))
                          .toList()),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(ScrollController scrollController) {
    final results = <_EmojiEntry>[];

    // Custom emojis
    for (final e in CustomEmojiCache.urls.entries) {
      if (e.key.contains(_query)) {
        results.add(_EmojiEntry(name: e.key, imageUrl: e.value));
      }
    }

    // Standard emojis
    for (final e in emojiMap.entries) {
      if (e.key.contains(_query)) {
        results.add(_EmojiEntry(name: e.key, unicode: e.value));
      }
    }

    if (results.isEmpty) {
      return Center(child: Text(context.l10n.nothingFound));
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) => _buildEmojiTile(results[index]),
    );
  }

  Widget _buildGrid(List<_EmojiEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Text(context.l10n.noEmojisYet, style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildEmojiTile(entries[index]),
    );
  }

  Widget _buildEmojiTile(_EmojiEntry entry) {
    return GestureDetector(
      onTap: () => _onSelect(entry.name),
      child: Tooltip(
        message: ':${entry.name}:',
        child: Center(
          child: entry.imageUrl != null
              ? Image.network(
                  entry.imageUrl!,
                  width: 28,
                  height: 28,
                  headers: _authHeaders,
                  errorBuilder: (_, _, _) =>
                      Text(':${entry.name}:', style: const TextStyle(fontSize: 10)),
                )
              : Text(entry.unicode ?? '?',
                  style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}

class _EmojiEntry {
  final String name;
  final String? unicode;
  final String? imageUrl;

  const _EmojiEntry({required this.name, this.unicode, this.imageUrl});
}
