import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/emoji_map.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/channel_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/user_status/user_status_cubit.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_display_name.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Always fetch fresh data via getUsersByIds (bypasses cache)
    final result = await sl<UserRepository>()
        .getUsersByIds([widget.userId]);
    result.fold(
      (failure) async {
        // Fallback to cache on server error
        final cached = await sl<UserRepository>().getUser(widget.userId);
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
            _error = 'User not found';
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingIndicator();
    if (_error != null) {
      return ErrorDisplay(message: _error!, onRetry: _loadUser);
    }

    final user = _user!;
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
            child:
                Text(user.position, style: AppTextStyles.bodySmall),
          ),
        ],
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
        if (_currentUserId != user.id) ...[
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
              label: const Text('Написать сообщение'),
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
    setState(() => _isSendingDm = true);
    final result = await sl<ChannelRepository>().createDirectChannel(
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
