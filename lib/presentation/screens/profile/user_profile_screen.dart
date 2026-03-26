import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/emoji_map.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/user.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/user_status/user_status_cubit.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/user_avatar.dart';
import '../../../core/l10n/l10n.dart';
import '../../widgets/user_display_name.dart';
import '../chat/widgets/pinned_messages_sheet.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  bool _isLoading = true;
  String? _error;
  List<Channel>? _commonChannels;

  // DM channel state
  Channel? _dmChannel;
  bool? _isMuted;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadCommonChannels();
    _loadDmChannel();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await currentSession.userRepository
        .getUsersByIds([widget.userId]);
    result.fold(
      (failure) async {
        final cached = await currentSession.userRepository.getUser(widget.userId);
        cached.fold(
          (_) => setState(() {
            _isLoading = false;
            _error = failure.message;
          }),
          (user) {
            if (mounted) {
              context.read<UserStatusCubit>().setCustomStatusFromUser(user);
            }
            setState(() {
              _isLoading = false;
              _user = user;
            });
          },
        );
      },
      (users) {
        if (users.isNotEmpty && mounted) {
          context
              .read<UserStatusCubit>()
              .setCustomStatusFromUser(users.first);
          setState(() {
            _isLoading = false;
            _user = users.first;
          });
        } else {
          setState(() {
            _isLoading = false;
            _error = context.l10n.userNotFound;
          });
        }
      },
    );
  }

  Future<void> _loadCommonChannels() async {
    final myId = _currentUserId;
    if (myId.isEmpty || myId == widget.userId) return;
    final result = await currentSession.channelRepository
        .getCommonChannels(myId, widget.userId);
    result.fold(
      (_) {},
      (channels) {
        if (mounted) setState(() => _commonChannels = channels);
      },
    );
  }

  Future<void> _loadDmChannel() async {
    final myId = _currentUserId;
    if (myId.isEmpty || myId == widget.userId) return;
    final result = await currentSession.channelRepository
        .createDirectChannel(myId, widget.userId);
    result.fold(
      (_) {},
      (channel) async {
        if (!mounted) return;
        setState(() => _dmChannel = channel);
        // Load mute status
        final memberResult = await currentSession.channelRepository
            .getChannelMemberInfo(channel.id, myId);
        memberResult.fold(
          (_) {},
          (info) {
            if (mounted) setState(() => _isMuted = info.isMuted);
          },
        );
      },
    );
  }

  Future<void> _toggleMute() async {
    final channel = _dmChannel;
    if (channel == null || _isMuted == null) return;
    HapticFeedback.selectionClick();
    final repo = currentSession.channelRepository;
    final result = _isMuted!
        ? await repo.unmuteChannel(channel.id, _currentUserId)
        : await repo.muteChannel(channel.id, _currentUserId);
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        }
      },
      (_) {
        if (mounted) setState(() => _isMuted = !_isMuted!);
      },
    );
  }

  void _showPinnedMessages() {
    final channel = _dmChannel;
    if (channel == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PinnedMessagesSheet(
        channelId: channel.id,
        onPostTap: (post) {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.userProfile)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingIndicator();
    if (_error != null) {
      return ErrorDisplay(message: _error!, onRetry: _loadUser);
    }

    final user = _user!;
    final isOtherUser = _currentUserId != user.id;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: UserAvatar(userId: user.id, radius: 50)),
        const SizedBox(height: 16),
        Center(
          child: UserDisplayName(
            userId: user.id,
            displayName: user.displayName,
            style: AppTextStyles.heading1,
            fallbackEmoji: user.customStatusEmoji,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '@${user.username}',
            style: AppTextStyles.bodySmall,
          ),
        ),
        if (user.position.isNotEmpty) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(user.position, style: AppTextStyles.bodySmall),
          ),
        ],
        // Last seen / online status
        BlocBuilder<UserStatusCubit, UserStatusState>(
          builder: (context, state) {
            final status = state.statuses[user.id];
            final lastActivityMs = state.lastActivity[user.id] ?? 0;

            String? lastSeenText;
            if (status == 'online') {
              lastSeenText = context.l10n.online;
            } else if (lastActivityMs > 0) {
              final formatted = DateFormatter.formatLastSeen(lastActivityMs);
              lastSeenText = formatted != null
                  ? context.l10n.lastSeenAt(formatted)
                  : context.l10n.lastSeenJustNow;
            }

            if (lastSeenText == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Text(
                  lastSeenText,
                  style: AppTextStyles.caption.copyWith(
                    color: status == 'online'
                        ? AppColors.online
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
        BlocBuilder<UserStatusCubit, UserStatusState>(
          builder: (context, state) {
            final cs = state.customStatuses[user.id];
            if (cs == null || cs.isEmpty) {
              return const SizedBox.shrink();
            }
            final shortcode = cs.emoji.replaceAll(':', '');
            final emojiChar = emojiMap[shortcode] ?? cs.emoji;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emojiChar,
                          style: const TextStyle(fontSize: 18)),
                      if (cs.text.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(cs.text, style: AppTextStyles.body),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (user.email.isNotEmpty) ...[
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(user.email),
          ),
        ],
        // DM channel actions (mute, pinned)
        if (isOtherUser && _dmChannel != null) ...[
          const Divider(height: 32),
          if (_isMuted != null)
            ListTile(
              leading: Icon(
                _isMuted! ? Icons.notifications_off : Icons.notifications,
              ),
              title: Text(
                _isMuted! ? context.l10n.unmute : context.l10n.mute,
              ),
              onTap: _toggleMute,
            ),
          ListTile(
            leading: const Icon(Icons.push_pin_outlined),
            title: Text(context.l10n.pinnedMessages),
            onTap: _showPinnedMessages,
          ),
        ],
        // Common channels
        if (isOtherUser && _commonChannels != null) ...[
          const SizedBox(height: 16),
          Text(
            context.l10n.commonChannels,
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 8),
          if (_commonChannels!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                context.l10n.noCommonChannels,
                style: AppTextStyles.caption,
              ),
            )
          else
            ...(_commonChannels!.map((channel) => ListTile(
                  leading: Icon(
                    channel.type == ChannelType.private_
                        ? Icons.lock
                        : channel.type == ChannelType.direct
                            ? Icons.person
                            : Icons.tag,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  title: Text(channel.displayName),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    context.push(
                      RouteNames.chatPath(channel.id),
                      extra: <String, dynamic>{
                        'channelName': channel.displayName,
                      },
                    );
                  },
                ))),
        ],
        if (isOtherUser) ...[
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              onPressed: _isSendingDm ? null : () => _openDirectMessage(user),
              icon: _isSendingDm
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.chat_bubble_outline),
              label: Text(context.l10n.sendMessage),
            ),
          ),
        ],
      ],
    );
  }

  String get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    return '';
  }

  bool _isSendingDm = false;

  Future<void> _openDirectMessage(User user) async {
    if (_dmChannel != null) {
      context.push(
        RouteNames.chatPath(_dmChannel!.id),
        extra: <String, dynamic>{
          'channelName': user.displayName,
          'dmUserId': user.id,
        },
      );
      return;
    }
    setState(() => _isSendingDm = true);
    final result = await currentSession.channelRepository.createDirectChannel(
      _currentUserId,
      user.id,
    );
    if (!mounted) return;
    setState(() => _isSendingDm = false);
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
  }
}
