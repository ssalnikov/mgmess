import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_stats.dart';
import '../../../domain/repositories/channel_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import 'channel_info_cubit.dart';

class ChannelInfoScreen extends StatefulWidget {
  final String channelId;
  final String channelName;
  final ChannelType? channelType;

  const ChannelInfoScreen({
    super.key,
    required this.channelId,
    this.channelName = '',
    this.channelType,
  });

  @override
  State<ChannelInfoScreen> createState() => _ChannelInfoScreenState();
}

class _ChannelInfoScreenState extends State<ChannelInfoScreen> {
  late final ChannelInfoCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ChannelInfoCubit(channelRepository: sl<ChannelRepository>());
    _cubit.loadChannelInfo(widget.channelId, currentUserId: _currentUserId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.channelName),
        ),
        body: BlocBuilder<ChannelInfoCubit, ChannelInfoState>(
          builder: (context, state) {
            if (state is ChannelInfoLoading) {
              return const LoadingIndicator();
            }
            if (state is ChannelInfoError) {
              return ErrorDisplay(
                message: state.message,
                onRetry: () => _cubit.loadChannelInfo(widget.channelId),
              );
            }
            if (state is ChannelInfoLoaded) {
              return _buildContent(state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(ChannelInfoLoaded state) {
    final channel = state.channel;
    final stats = state.stats;
    final isDm = channel.isDirect || channel.isGroup;
    final canEdit = state.isCurrentUserAdmin && !isDm;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Channel icon and name
        _buildHeader(channel),
        const SizedBox(height: 24),

        // Quick actions
        _buildQuickActions(channel, canEdit: canEdit),
        const Divider(height: 32),

        // Header
        if (channel.header.isNotEmpty && !isDm) ...[
          _buildSection('Header', channel.header),
          const Divider(height: 32),
        ],

        // Purpose
        if (channel.purpose.isNotEmpty && !isDm) ...[
          _buildSection('Purpose', channel.purpose),
          const Divider(height: 32),
        ],

        // Members
        _buildMembersTile(stats, state),
        const Divider(height: 1),

        // Pinned Messages
        ListTile(
          leading: const Icon(Icons.push_pin_outlined),
          title: const Text('Pinned Messages'),
          trailing: stats.pinnedPostCount > 0
              ? Text(
                  '${stats.pinnedPostCount}',
                  style: AppTextStyles.bodySmall,
                )
              : null,
          onTap: () => Navigator.pop(context),
        ),

        if (!isDm) ...[
          const Divider(height: 32),
          // Leave Channel
          _buildLeaveButton(channel),
        ],
      ],
    );
  }

  Widget _buildHeader(Channel channel) {
    final IconData typeIcon;
    final String typeLabel;

    if (channel.isDirect) {
      typeIcon = Icons.person;
      typeLabel = 'Direct Message';
    } else if (channel.isGroup) {
      typeIcon = Icons.group;
      typeLabel = 'Group Message';
    } else if (channel.isPrivate) {
      typeIcon = Icons.lock;
      typeLabel = 'Private Channel';
    } else {
      typeIcon = Icons.tag;
      typeLabel = 'Public Channel';
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.accent.withValues(alpha: 0.1),
          child: Icon(typeIcon, size: 36, color: AppColors.accent),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            channel.displayName,
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Text(typeLabel, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildQuickActions(Channel channel, {bool canEdit = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickAction(
            icon: channel.isMuted
                ? Icons.notifications_off
                : Icons.notifications,
            label: channel.isMuted ? 'Unmute' : 'Mute',
            onTap: () {
              HapticFeedback.selectionClick();
              _cubit.toggleMute(
                widget.channelId,
                _currentUserId,
                channel.isMuted,
              );
            },
          ),
          if (canEdit)
            _QuickAction(
              icon: Icons.edit,
              label: 'Edit',
              onTap: () async {
                HapticFeedback.selectionClick();
                final updated = await context.push<bool>(
                  RouteNames.channelEditPath(widget.channelId),
                );
                if (updated == true) {
                  _cubit.loadChannelInfo(
                    widget.channelId,
                    currentUserId: _currentUserId,
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.username.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildMembersTile(
    ChannelStats stats,
    ChannelInfoLoaded state,
  ) {
    return ListTile(
      leading: const Icon(Icons.people_outline),
      title: Text('Members (${stats.memberCount})'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push(
          RouteNames.channelMembersPath(widget.channelId),
        );
      },
    );
  }

  Widget _buildLeaveButton(Channel channel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton.icon(
        onPressed: () => _confirmLeave(channel),
        icon: const Icon(Icons.exit_to_app, color: AppColors.error),
        label: const Text(
          'Leave Channel',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  void _confirmLeave(Channel channel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Channel'),
        content: Text(
          'Are you sure you want to leave "${channel.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _cubit.leaveChannel(
                widget.channelId,
                _currentUserId,
              );
              if (mounted) {
                context.go(RouteNames.channels);
              }
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
