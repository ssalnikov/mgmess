import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/custom_emoji_cache.dart';
import '../../../../core/utils/emoji_map.dart';
import '../../../../core/di/injection.dart';
import '../../../widgets/user_avatar.dart';

/// Shows who reacted with each emoji on a post.
class ReactionsListSheet extends StatefulWidget {
  final Map<String, List<String>> reactions;
  final String? initialEmoji;

  const ReactionsListSheet({
    super.key,
    required this.reactions,
    this.initialEmoji,
  });

  @override
  State<ReactionsListSheet> createState() => _ReactionsListSheetState();
}

class _ReactionsListSheetState extends State<ReactionsListSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<MapEntry<String, List<String>>> _entries;
  Map<String, String>? _authHeaders;

  @override
  void initState() {
    super.initState();
    _entries = widget.reactions.entries.toList();
    final initialIndex = widget.initialEmoji != null
        ? _entries.indexWhere((e) => e.key == widget.initialEmoji).clamp(0, _entries.length - 1)
        : 0;
    _tabController = TabController(
      length: _entries.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _loadHeaders();
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildEmojiLabel(String emojiName) {
    final emojiChar = emojiMap[emojiName];
    final customUrl = CustomEmojiCache.getUrl(emojiName);
    if (emojiChar != null) {
      return Text(emojiChar, style: const TextStyle(fontSize: 20));
    } else if (customUrl != null && _authHeaders != null) {
      return Image.network(
        customUrl,
        width: 20,
        height: 20,
        headers: _authHeaders,
        errorBuilder: (_, _, _) =>
            Text(':$emojiName:', style: const TextStyle(fontSize: 10)),
      );
    }
    return Text(':$emojiName:', style: const TextStyle(fontSize: 10));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
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
            const SizedBox(height: 8),
            // Tabs — one per emoji
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: _entries.map((entry) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildEmojiLabel(entry.key),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.value.length}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _entries.map((entry) {
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      final userId = entry.value[index];
                      return _ReactionUserTile(userId: userId);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReactionUserTile extends StatefulWidget {
  final String userId;

  const _ReactionUserTile({required this.userId});

  @override
  State<_ReactionUserTile> createState() => _ReactionUserTileState();
}

class _ReactionUserTileState extends State<_ReactionUserTile> {
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final result = await currentSession.userRepository.getUser(widget.userId);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _displayName = widget.userId),
      (user) => setState(() => _displayName = user.displayName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(userId: widget.userId, radius: 18),
      title: Text(
        _displayName.isEmpty ? '...' : _displayName,
        style: AppTextStyles.channelName,
      ),
    );
  }
}
