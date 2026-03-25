import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_stats.dart';
import '../../../domain/repositories/channel_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event.dart';
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

        // Read-only indicator
        if (state.isReadOnly) ...[
          _buildReadOnlyIndicator(),
          const SizedBox(height: 16),
        ],

        // Quick actions
        _buildQuickActions(channel, canEdit: canEdit),
        const Divider(height: 32),

        // Header
        if (channel.header.isNotEmpty && !isDm) ...[
          _buildSection(context.l10n.header, channel.header),
          const Divider(height: 32),
        ],

        // Purpose
        if (channel.purpose.isNotEmpty && !isDm) ...[
          _buildSection(context.l10n.purpose, channel.purpose),
          const Divider(height: 32),
        ],

        // Notification settings
        if (!isDm) ...[
          _buildNotificationSettings(channel),
          const Divider(height: 1),
        ],

        // Members
        _buildMembersTile(stats, state),
        const Divider(height: 1),

        // Pinned Messages
        ListTile(
          leading: const Icon(Icons.push_pin_outlined),
          title: Text(context.l10n.pinnedMessages),
          trailing: stats.pinnedPostCount > 0
              ? Text(
                  '${stats.pinnedPostCount}',
                  style: AppTextStyles.bodySmall,
                )
              : null,
          onTap: () => Navigator.pop(context),
        ),
        const Divider(height: 1),

        // Files
        ListTile(
          leading: const Icon(Icons.attach_file),
          title: Text(context.l10n.channelFiles),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(
              RouteNames.channelFilesPath(widget.channelId),
              extra: {'channelName': channel.displayName},
            );
          },
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
      typeLabel = context.l10n.directMessage;
    } else if (channel.isGroup) {
      typeIcon = Icons.group;
      typeLabel = context.l10n.groupMessage;
    } else if (channel.isPrivate) {
      typeIcon = Icons.lock;
      typeLabel = context.l10n.privateChannel;
    } else {
      typeIcon = Icons.tag;
      typeLabel = context.l10n.publicChannel;
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

  Widget _buildReadOnlyIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            context.l10n.readOnlyChannel,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
            label: channel.isMuted ? context.l10n.unmute : context.l10n.mute,
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
              label: context.l10n.edit,
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
      title: Text(context.l10n.membersWithCount(stats.memberCount)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push(
          RouteNames.channelMembersPath(widget.channelId),
        );
      },
    );
  }

  Widget _buildNotificationSettings(Channel channel) {
    return ListTile(
      leading: const Icon(Icons.notifications_outlined),
      title: Text(context.l10n.notificationPreferences),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showNotificationSettingsSheet(channel),
    );
  }

  void _showNotificationSettingsSheet(Channel channel) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ChannelNotificationSheet(
        channelId: widget.channelId,
        channelName: channel.displayName,
      ),
    );
  }

  Widget _buildLeaveButton(Channel channel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton.icon(
        onPressed: () => _confirmLeave(channel),
        icon: const Icon(Icons.exit_to_app, color: AppColors.error),
        label: Text(
          context.l10n.leaveChannel,
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  void _confirmLeave(Channel channel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.leaveChannel),
        content: Text(
          context.l10n.leaveChannelConfirm(channel.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
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
            child: Text(
              context.l10n.leave,
              style: const TextStyle(color: AppColors.error),
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

class _ChannelNotificationSheet extends StatefulWidget {
  final String channelId;
  final String channelName;

  const _ChannelNotificationSheet({
    required this.channelId,
    required this.channelName,
  });

  @override
  State<_ChannelNotificationSheet> createState() =>
      _ChannelNotificationSheetState();
}

class _ChannelNotificationSheetState extends State<_ChannelNotificationSheet> {
  String _filter = 'default';
  bool _loading = true;

  static String _prefKey(String channelId) =>
      'channel_notification_$channelId';

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _filter = prefs.getString(_prefKey(widget.channelId)) ?? 'default';
      _loading = false;
    });
  }

  Future<void> _setFilter(String value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == 'default') {
      await prefs.remove(_prefKey(widget.channelId));
    } else {
      await prefs.setString(_prefKey(widget.channelId), value);
    }
    setState(() => _filter = value);

    // Update the notification bloc with the new per-channel settings
    if (mounted) {
      try {
        context.read<NotificationBloc>().add(
              NotificationChannelSettingChanged(
                channelId: widget.channelId,
                filter: value,
              ),
            );
      } catch (_) {}
    }
  }

  static List<({String value, String label, String subtitle, IconData icon})> _getOptions(BuildContext context) => [
    (value: 'default', label: context.l10n.defaultNotif, subtitle: context.l10n.useGlobalSetting, icon: Icons.settings),
    (value: 'all', label: context.l10n.allMessages, subtitle: context.l10n.notifyEveryMessage, icon: Icons.notifications_active),
    (value: 'mentions', label: context.l10n.mentionsOnly, subtitle: context.l10n.onlyWhenMentioned, icon: Icons.alternate_email),
    (value: 'none', label: context.l10n.nothing, subtitle: context.l10n.neverNotify, icon: Icons.notifications_off),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.notificationsChannelTitle(widget.channelName),
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _filter,
            onChanged: (v) {
              if (v != null) _setFilter(v);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in _getOptions(context))
                  RadioListTile<String>(
                    value: option.value,
                    title: Text(option.label),
                    subtitle: Text(option.subtitle, style: AppTextStyles.caption),
                    secondary: Icon(option.icon, color: AppColors.accent),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
