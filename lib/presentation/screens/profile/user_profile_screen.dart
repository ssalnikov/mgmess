import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/user_avatar.dart';

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

    final result = await sl<UserRepository>().getUser(widget.userId);
    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _error = failure.message;
      }),
      (user) => setState(() {
        _isLoading = false;
        _user = user;
      }),
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
          child:
              Text(user.displayName, style: AppTextStyles.heading1),
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
