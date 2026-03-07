import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/custom_emoji_cache.dart';
import '../../../../core/utils/emoji_map.dart';

/// Full emoji picker with search, showing both standard and custom server emojis.
class EmojiPickerSheet extends StatefulWidget {
  final void Function(String emojiName) onEmojiSelected;

  const EmojiPickerSheet({super.key, required this.onEmojiSelected});

  @override
  State<EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<EmojiPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  Map<String, String>? _authHeaders;

  @override
  void initState() {
    super.initState();
    CustomEmojiCache.ensureLoaded();
    _loadHeaders();
  }

  Future<void> _loadHeaders() async {
    final token = await sl<SecureStorage>().getToken();
    if (mounted) {
      setState(() {
        _authHeaders = {
          if (token != null) 'Authorization': 'Bearer $token',
        };
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customUrls = CustomEmojiCache.urls;
    final filtered = _buildFilteredList(customUrls);

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
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search emoji...',
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
            if (filtered.isEmpty)
              const Expanded(
                child: Center(child: Text('Nothing found')),
              )
            else
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return _buildEmojiTile(entry);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  List<_EmojiEntry> _buildFilteredList(Map<String, String> customUrls) {
    final results = <_EmojiEntry>[];

    // Custom emojis first
    for (final e in customUrls.entries) {
      if (_query.isEmpty || e.key.contains(_query)) {
        results.add(_EmojiEntry(name: e.key, imageUrl: e.value));
      }
    }

    // Standard emojis
    for (final e in emojiMap.entries) {
      if (_query.isEmpty || e.key.contains(_query)) {
        results.add(_EmojiEntry(name: e.key, unicode: e.value));
      }
    }

    return results;
  }

  Widget _buildEmojiTile(_EmojiEntry entry) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
        widget.onEmojiSelected(entry.name);
      },
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
              : Text(entry.unicode!, style: const TextStyle(fontSize: 28)),
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
