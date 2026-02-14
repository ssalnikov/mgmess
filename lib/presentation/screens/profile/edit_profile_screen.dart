import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _positionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final user =
        authState is AuthAuthenticated ? authState.user : null;
    _firstNameController =
        TextEditingController(text: user?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: user?.lastName ?? '');
    _nicknameController =
        TextEditingController(text: user?.nickname ?? '');
    _positionController =
        TextEditingController(text: user?.position ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _isSaving = true);

    final repo = sl<UserRepository>();
    final result = await repo.updateUser(authState.user.id, {
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'nickname': _nicknameController.text,
      'position': _positionController.text,
    });

    setState(() => _isSaving = false);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        }
      },
      (_) {
        // Refresh auth state with updated user
        context.read<AuthBloc>().add(const AuthCheckSession());
        if (mounted) context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration:
                  const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration:
                  const InputDecoration(labelText: 'Last Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nicknameController,
              decoration:
                  const InputDecoration(labelText: 'Nickname'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _positionController,
              decoration:
                  const InputDecoration(labelText: 'Position'),
            ),
          ],
        ),
      ),
    );
  }
}
