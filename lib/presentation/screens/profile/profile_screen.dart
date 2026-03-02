import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/services.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/user_status/user_status_cubit.dart';
import '../../widgets/restart_widget.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: Text('Not authenticated'));
          }
          final user = state.user;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: UserAvatar(userId: user.id, radius: 50),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.displayName,
                  style: AppTextStyles.heading1,
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
                  child: Text(
                    user.position,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _StatusSelector(userId: user.id),
              const SizedBox(height: 24),
              _ProfileItem(
                icon: Icons.email,
                label: 'Email',
                value: user.email,
              ),
              _ProfileItem(
                icon: Icons.person,
                label: 'First Name',
                value: user.firstName,
              ),
              _ProfileItem(
                icon: Icons.person,
                label: 'Last Name',
                value: user.lastName,
              ),
              if (user.nickname.isNotEmpty)
                _ProfileItem(
                  icon: Icons.badge,
                  label: 'Nickname',
                  value: user.nickname,
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push(RouteNames.editProfile),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push(RouteNames.notificationSettings),
                icon: const Icon(Icons.notifications_outlined),
                label: const Text('Notification Settings'),
              ),
              const SizedBox(height: 12),
              _ProfileItem(
                icon: Icons.dns,
                label: 'Server',
                value: AppConfig.serverUrl,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showChangeServerDialog(context),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Change Server'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangeServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Server'),
        content: const Text(
          'You will be signed out and redirected to the server selection screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              await AppConfig.clearServerUrl();
              await GetIt.instance.reset();
              if (context.mounted) {
                RestartWidget.restartApp(context);
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final String userId;

  const _StatusSelector({required this.userId});

  static const _statusOptions = [
    _StatusOption('online', 'В сети', 'Вы видны как активный', AppColors.online),
    _StatusOption('away', 'Нет на месте', 'Вы видны как отсутствующий', AppColors.away),
    _StatusOption('dnd', 'Не беспокоить', 'Уведомления отключены', AppColors.dnd),
    _StatusOption('offline', 'Не в сети', 'Вы видны как отключённый', AppColors.offline),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserStatusCubit, UserStatusState>(
      builder: (context, state) {
        final currentStatus = state.statuses[userId] ?? 'offline';
        final option = _statusOptions.firstWhere(
          (o) => o.key == currentStatus,
          orElse: () => _statusOptions.last,
        );
        return InkWell(
          onTap: () => _showStatusSheet(context, currentStatus),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(option.label, style: AppTextStyles.body),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStatusSheet(BuildContext context, String currentStatus) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
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
              const Text('Статус', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              for (final option in _statusOptions)
                ListTile(
                  leading: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(option.label),
                  subtitle: Text(option.description, style: AppTextStyles.caption),
                  trailing: currentStatus == option.key
                      ? const Icon(Icons.check, color: AppColors.accent)
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    if (currentStatus != option.key) {
                      HapticFeedback.selectionClick();
                      context.read<UserStatusCubit>().updateStatus(
                            userId,
                            option.key,
                          );
                    }
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _StatusOption {
  final String key;
  final String label;
  final String description;
  final Color color;

  const _StatusOption(this.key, this.label, this.description, this.color);
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value, style: AppTextStyles.body),
            ],
          ),
        ],
      ),
    );
  }
}
