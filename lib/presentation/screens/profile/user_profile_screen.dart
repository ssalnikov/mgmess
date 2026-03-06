import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/emoji_map.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/user_repository.dart';
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
      ],
    );
  }
}
