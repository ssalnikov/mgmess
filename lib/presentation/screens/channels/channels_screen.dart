import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/repositories/channel_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/websocket/websocket_bloc.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';
import '../../widgets/user_avatar.dart';
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Channels'),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocBuilder<ChannelsBloc, ChannelsState>(
                builder: (context, state) {
                  if (state.isLoading && state.channels.isEmpty) {
                    return const LoadingIndicator(
                        message: 'Loading channels...');
                  }
                  if (state.error != null && state.channels.isEmpty) {
                    return ErrorDisplay(
                      message: state.error!,
                      onRetry: () =>
                          _channelsBloc.add(const RefreshChannels()),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      _channelsBloc.add(const RefreshChannels());
                    },
                    child: ListView.builder(
                      itemCount: state.filteredChannels.length,
                      itemBuilder: (context, index) =>
                          _ChannelListTile(
                        channel: state.filteredChannels[index],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
          hintText: 'Search channels...',
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

class _ChannelListTile extends StatelessWidget {
  final Channel channel;

  const _ChannelListTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeading(),
      title: Text(
        channel.displayName.isNotEmpty
            ? channel.displayName
            : channel.name,
        style: channel.hasUnread
            ? AppTextStyles.channelName
                .copyWith(fontWeight: FontWeight.bold)
            : AppTextStyles.channelName,
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
        context.push(
          RouteNames.chatPath(channel.id),
          extra: channel.displayName,
        );
      },
    );
  }

  Widget _buildLeading() {
    if (channel.isDirect) {
      // DM: extract other user ID from channel name
      final parts = channel.name.split('__');
      final otherId = parts.length == 2 ? parts.first : channel.id;
      return UserAvatar(userId: otherId);
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

  Widget? _buildTrailing() {
    if (channel.hasMention) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.unreadBadge,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          channel.mentionCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    if (channel.hasUnread) {
      return Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
      );
    }
    return null;
  }
}
