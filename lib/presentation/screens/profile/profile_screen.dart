import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
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
              const SizedBox(height: 32),
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
