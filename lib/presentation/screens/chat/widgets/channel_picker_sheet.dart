import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/channel.dart';
import '../../../../domain/repositories/channel_repository.dart';
import '../../../../domain/repositories/user_repository.dart';

class ChannelPickerSheet extends StatefulWidget {
  final String userId;
  final String teamId;
  final String? excludeChannelId;

  const ChannelPickerSheet({
    super.key,
    required this.userId,
    required this.teamId,
    this.excludeChannelId,
  });

  @override
  State<ChannelPickerSheet> createState() => _ChannelPickerSheetState();
}

class _ChannelPickerSheetState extends State<ChannelPickerSheet> {
  List<Channel> _channels = [];
  List<Channel> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  final Map<String, String> _dmDisplayNames = {};

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    final result = await sl<ChannelRepository>().getChannelsForUser(
      widget.userId,
      widget.teamId,
    );
    if (!mounted) return;

    result.fold(
      (_) => setState(() => _isLoading = false),
      (channels) {
        final filtered = channels
            .where((c) => c.id != widget.excludeChannelId)
            .toList();
        setState(() {
          _channels = filtered;
          _filtered = filtered;
          _isLoading = false;
        });
        _resolveDmNames(filtered);
      },
    );
  }

  Future<void> _resolveDmNames(List<Channel> channels) async {
    final userRepo = sl<UserRepository>();
    for (final ch in channels) {
      if (!ch.isDirect) continue;
      final parts = ch.name.split('__');
      if (parts.length != 2) continue;
      final otherId =
          parts.first == widget.userId ? parts.last : parts.first;
      final result = await userRepo.getUser(otherId);
      if (!mounted) return;
      result.fold((_) {}, (user) {
        setState(() {
          _dmDisplayNames[ch.id] = user.displayName;
        });
      });
    }
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _channels.where((ch) {
        final name = _getDisplayName(ch).toLowerCase();
        return name.contains(q);
      }).toList();
    });
  }

  String _getDisplayName(Channel ch) {
    if (ch.isDirect && _dmDisplayNames.containsKey(ch.id)) {
      return _dmDisplayNames[ch.id]!;
    }
    return ch.displayName.isNotEmpty ? ch.displayName : ch.name;
  }

  IconData _getChannelIcon(Channel ch) {
    switch (ch.type) {
      case ChannelType.open:
        return Icons.tag;
      case ChannelType.private_:
        return Icons.lock;
      case ChannelType.direct:
        return Icons.person;
      case ChannelType.group:
        return Icons.group;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search channels...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: _onSearch,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final ch = _filtered[index];
                        return ListTile(
                          leading: Icon(
                            _getChannelIcon(ch),
                            color: AppColors.primary,
                          ),
                          title: Text(
                            _getDisplayName(ch),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.pop(context, ch),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
