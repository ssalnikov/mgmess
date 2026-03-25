import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/channel_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event.dart';
import '../../blocs/user_status/user_status_cubit.dart';
import '../../blocs/websocket/websocket_bloc.dart';
import 'widgets/category_header.dart';
import 'widgets/channel_skeleton.dart';
import '../../widgets/error_display.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_display_name.dart';
import 'channels_bloc.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  late final ChannelsBloc _channelsBloc;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _channelsBloc = ChannelsBloc(
      channelRepository: sl<ChannelRepository>(),
      userRepository: sl<UserRepository>(),
    );
    _loadChannels();
    _subscribeToWs();
  }

  void _loadChannels() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _channelsBloc.add(LoadChannels(
        userId: authState.user.id,
        teamId: authState.teamId,
      ));
    }
  }

  void _subscribeToWs() {
    try {
      final wsBloc = context.read<WebSocketBloc>();
      _channelsBloc.subscribeToWs(wsBloc.wsEvents);
    } catch (_) {
      // WebSocket bloc not available yet
    }
  }

  String get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    return '';
  }

  @override
  void dispose() {
    _channelsBloc.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _channelsBloc,
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) {
          if (prev is AuthAuthenticated && curr is AuthAuthenticated) {
            return prev.teamId != curr.teamId;
          }
          return false;
        },
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            _channelsBloc.add(LoadChannels(
              userId: state.user.id,
              teamId: state.teamId,
            ));
          }
        },
        child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.channels),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.push(RouteNames.search),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateOptions(context),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocConsumer<ChannelsBloc, ChannelsState>(
                listener: (context, state) {
                  final mutedIds = state.channels
                      .where((c) => c.isMuted)
                      .map((c) => c.id)
                      .toSet();
                  context.read<NotificationBloc>().add(
                        NotificationUpdateMutedChannels(
                          mutedChannelIds: mutedIds,
                        ),
                      );
                },
                builder: (context, state) {
                  if (state.isLoading && state.channels.isEmpty) {
                    return const ChannelSkeletonList();
                  }
                  if (state.error != null && state.channels.isEmpty) {
                    return ErrorDisplay(
                      message: state.error!,
                      onRetry: () =>
                          _channelsBloc.add(const RefreshChannels()),
                    );
                  }
                  if (state.hasSearchQuery) {
                    return _buildSearchResults(state);
                  }
                  return _buildGroupedChannelList(state);
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.tag),
              title: Text(context.l10n.newChannel),
              subtitle: Text(context.l10n.createChannelSubtitle),
              onTap: () {
                Navigator.pop(ctx);
                context.push(RouteNames.createChannel);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: Text(context.l10n.newMessage),
              subtitle: Text(context.l10n.startDirectOrGroupMessage),
              onTap: () {
                Navigator.pop(ctx);
                context.push(RouteNames.createGroupDm);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadsRow() {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.forum_outlined, color: AppColors.primary, size: 20),
      ),
      title: Text(context.l10n.threads),
      dense: true,
      onTap: () => context.push(RouteNames.threads),
    );
  }

  Widget _buildDraftsRow() {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.edit_note, color: AppColors.primary, size: 20),
      ),
      title: Text(context.l10n.drafts),
      dense: true,
      onTap: () => context.push(RouteNames.drafts),
    );
  }

  Widget _buildGroupedChannelList(ChannelsState state) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.selectionClick();
        _channelsBloc.add(const RefreshChannels());
      },
      child: CustomScrollView(
        slivers: [
          // Fixed items at top
          SliverToBoxAdapter(child: _buildThreadsRow()),
          SliverToBoxAdapter(child: _buildDraftsRow()),

          // Grouped sections
          for (final section in state.sections) ...[
            // Section header
            if (section.title.isNotEmpty)
              SliverToBoxAdapter(
                child: CategoryHeader(
                  title: section.title,
                  collapsed: section.collapsed,
                  onToggle: section.isUnreads
                      ? null
                      : () => _channelsBloc.add(
                            ToggleCategoryCollapsed(
                              categoryId: section.id,
                            ),
                          ),
                  unreadCount: section.isUnreads
                      ? section.channels
                          .where((c) => c.hasUnread || c.hasMention)
                          .length
                      : null,
                ),
              ),
            // Section channels
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final channel = section.channels[index];
                  return BlocSelector<ChannelsBloc, ChannelsState, bool>(
                    selector: (state) =>
                        state.readOnlyChannelIds.contains(channel.id),
                    builder: (context, isReadOnly) => _ChannelListTile(
                      key: ValueKey(channel.id),
                      channel: channel,
                      currentUserId: _currentUserId,
                      isReadOnly: isReadOnly,
                    ),
                  );
                },
                childCount: section.channels.length,
              ),
            ),
          ],

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ChannelsState state) {
    final sections = <Widget>[];

    // Section: Joined channels
    if (state.filteredChannels.isNotEmpty) {
      sections.add(_buildSectionHeader(context.l10n.channels));
      for (final channel in state.filteredChannels) {
        sections.add(_ChannelListTile(
          key: ValueKey(channel.id),
          channel: channel,
          currentUserId: _currentUserId,
          isReadOnly: state.readOnlyChannelIds.contains(channel.id),
        ));
      }
    }

    // Section: Other public channels (from server autocomplete)
    if (state.serverChannels.isNotEmpty) {
      sections.add(_buildSectionHeader(context.l10n.otherChannels));
      for (final channel in state.serverChannels) {
        sections.add(_ChannelListTile(
          key: ValueKey('server_${channel.id}'),
          channel: channel,
          currentUserId: _currentUserId,
        ));
      }
    }

    // Section: Users (for starting DM)
    if (state.userResults.isNotEmpty) {
      sections.add(_buildSectionHeader(context.l10n.users));
      for (final user in state.userResults) {
        sections.add(_UserSearchTile(
          key: ValueKey('user_${user.id}'),
          user: user,
          currentUserId: _currentUserId,
        ));
      }
    }

    if (sections.isEmpty && !state.isSearching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context.l10n.noResultsFound,
            style: AppTextStyles.bodySmall,
          ),
        ),
      );
    }

    return ListView(
      children: [
        ...sections,
        if (state.isSearching)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: context.l10n.searchChannels,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _channelsBloc
                        .add(const SearchChannels(query: ''));
                  },
                )
              : null,
          isDense: true,
        ),
        onChanged: (query) {
          _channelsBloc.add(SearchChannels(query: query));
          setState(() {});
        },
      ),
    );
  }
}

class _ChannelListTile extends StatefulWidget {
  final Channel channel;
  final String currentUserId;
  final bool isReadOnly;

  const _ChannelListTile({
    super.key,
    required this.channel,
    required this.currentUserId,
    this.isReadOnly = false,
  });

  @override
  State<_ChannelListTile> createState() => _ChannelListTileState();
}

class _ChannelListTileState extends State<_ChannelListTile> {
  String? _dmDisplayName;
  String? _dmUserId;

  Channel get channel => widget.channel;

  @override
  void initState() {
    super.initState();
    if (channel.isDirect) {
      _fetchDmUserName();
    }
  }

  @override
  void didUpdateWidget(covariant _ChannelListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channel.id != widget.channel.id) {
      _dmDisplayName = null;
      _dmUserId = null;
      if (channel.isDirect) {
        _fetchDmUserName();
      }
    }
  }

  void _fetchDmUserName() {
    final parts = channel.name.split('__');
    if (parts.length != 2) return;
    final otherId = parts.first == widget.currentUserId
        ? parts.last
        : parts.first;
    _dmUserId = otherId;
    sl<UserRepository>().getUser(otherId).then((result) {
      if (!mounted) return;
      result.fold((_) {}, (user) {
        context.read<UserStatusCubit>().setCustomStatusFromUser(user);
        setState(() => _dmDisplayName = user.displayName);
      });
    });
  }

  String get _title {
    if (channel.isDirect && _dmDisplayName != null) {
      return _dmDisplayName!;
    }
    return channel.displayName.isNotEmpty
        ? channel.displayName
        : channel.name;
  }

  @override
  Widget build(BuildContext context) {
    final isMuted = channel.isMuted;
    return ListTile(
      leading: _buildLeading(),
      title: _dmUserId != null
          ? UserDisplayName(
              userId: _dmUserId!,
              displayName: _title,
              style: (channel.hasUnread && !isMuted)
                  ? AppTextStyles.channelName
                      .copyWith(fontWeight: FontWeight.bold)
                  : AppTextStyles.channelName.copyWith(
                      color: isMuted ? AppColors.textSecondary : null,
                    ),
            )
          : Text(
              _title,
              style: (channel.hasUnread && !isMuted)
                  ? AppTextStyles.channelName
                      .copyWith(fontWeight: FontWeight.bold)
                  : AppTextStyles.channelName.copyWith(
                      color: isMuted ? AppColors.textSecondary : null,
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      subtitle: channel.lastPostAt > 0
          ? Text(
              DateFormatter.formatChannelTime(channel.lastPostAt),
              style: AppTextStyles.caption,
            )
          : null,
      trailing: _buildTrailing(),
      onTap: () {
        context.read<ChannelsBloc>().add(
              MarkChannelAsRead(channelId: channel.id),
            );
        final extra = <String, dynamic>{
          'channelName': _title,
          'lastViewedAt': channel.lastViewedAt,
        };
        if (channel.isDirect) {
          final parts = channel.name.split('__');
          if (parts.length == 2) {
            extra['dmUserId'] = parts.first == widget.currentUserId
                ? parts.last
                : parts.first;
          }
        }
        context.push(
          RouteNames.chatPath(channel.id),
          extra: extra,
        );
      },
      onLongPress: () => _showChannelActions(context),
    );
  }

  void _showChannelActions(BuildContext context) {
    final isMuted = channel.isMuted;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isMuted ? Icons.notifications : Icons.notifications_off,
              ),
              title: Text(isMuted ? context.l10n.unmute : context.l10n.mute),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ChannelsBloc>().add(
                      ToggleMuteChannel(
                        channelId: channel.id,
                        userId: widget.currentUserId,
                      ),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (channel.isDirect) {
      final parts = channel.name.split('__');
      final otherId = parts.length == 2
          ? (parts.first == widget.currentUserId ? parts.last : parts.first)
          : channel.id;
      return UserAvatar(
        userId: otherId,
        heroTag: 'channel_avatar_${channel.id}',
      );
    }

    IconData icon;
    switch (channel.type) {
      case ChannelType.open:
        icon = Icons.tag;
      case ChannelType.private_:
        icon = Icons.lock;
      case ChannelType.group:
        icon = Icons.group;
      default:
        icon = Icons.tag;
    }

    return CircleAvatar(
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }

  static const _lockIcon = Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary);

  Widget? _buildTrailing() {
    Widget? badge;

    if (channel.isMuted) {
      badge = const Icon(
        Icons.notifications_off,
        size: 18,
        color: AppColors.textSecondary,
      );
    } else if (channel.hasMention) {
      badge = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (channel.hasUrgent)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.priority_high,
                size: 16,
                color: Colors.red.shade700,
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.unreadBadge,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              channel.mentionCountRoot.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else if (channel.hasUnread) {
      badge = Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
      );
    }

    if (!widget.isReadOnly) return badge;
    if (badge == null) return _lockIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 4),
          child: _lockIcon,
        ),
        badge,
      ],
    );
  }
}

class _UserSearchTile extends StatelessWidget {
  final User user;
  final String currentUserId;

  const _UserSearchTile({
    super.key,
    required this.user,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(userId: user.id),
      title: UserDisplayName(
        userId: user.id,
        displayName: user.displayName,
        style: AppTextStyles.channelName,
        fallbackEmoji: user.customStatusEmoji,
      ),
      subtitle: Text(
        '@${user.username}',
        style: AppTextStyles.caption,
      ),
      onTap: () async {
        final channelRepo = sl<ChannelRepository>();
        final result = await channelRepo.createDirectChannel(
          currentUserId,
          user.id,
        );
        if (!context.mounted) return;
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message)),
            );
          },
          (channel) {
            context.push(
              RouteNames.chatPath(channel.id),
              extra: <String, dynamic>{
                'channelName': user.displayName,
                'dmUserId': user.id,
              },
            );
          },
        );
      },
    );
  }
}
