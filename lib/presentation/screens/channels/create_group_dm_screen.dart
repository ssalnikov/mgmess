import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/user.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/user_avatar.dart';

class CreateGroupDmScreen extends StatefulWidget {
  const CreateGroupDmScreen({super.key});

  @override
  State<CreateGroupDmScreen> createState() => _CreateGroupDmScreenState();
}

class _CreateGroupDmScreenState extends State<CreateGroupDmScreen> {
  final _searchController = TextEditingController();
  final _selectedUsers = <User>[];
  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _isCreating = false;
  Timer? _debounce;

  String get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    return '';
  }

  String get _teamId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.teamId;
    return '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final result = await currentSession.userRepository.autocompleteUsers(
        query,
        teamId: _teamId,
      );
      if (!mounted) return;
      result.fold(
        (_) => setState(() => _isSearching = false),
        (users) {
          final selectedIds = _selectedUsers.map((u) => u.id).toSet();
          setState(() {
            _searchResults = users
                .where((u) =>
                    u.id != _currentUserId && !selectedIds.contains(u.id))
                .toList();
            _isSearching = false;
          });
        },
      );
    });
  }

  void _addUser(User user) {
    setState(() {
      _selectedUsers.add(user);
      _searchResults.removeWhere((u) => u.id == user.id);
      _searchController.clear();
    });
  }

  void _removeUser(User user) {
    setState(() => _selectedUsers.removeWhere((u) => u.id == user.id));
  }

  Future<void> _create() async {
    if (_selectedUsers.isEmpty) return;

    setState(() => _isCreating = true);

    final userIds = [_currentUserId, ..._selectedUsers.map((u) => u.id)];

    final channelRepo = currentSession.channelRepository;
    final result = _selectedUsers.length == 1
        ? await channelRepo.createDirectChannel(
            _currentUserId, _selectedUsers.first.id)
        : await channelRepo.createGroupChannel(userIds);

    if (!mounted) return;
    setState(() => _isCreating = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (channel) {
        HapticFeedback.lightImpact();
        final name = _selectedUsers.map((u) => u.displayName).join(', ');
        context.go(
          RouteNames.chatPath(channel.id),
          extra: <String, dynamic>{'channelName': name},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.newMessage),
        actions: [
          TextButton(
            onPressed:
                (_selectedUsers.isEmpty || _isCreating) ? null : _create,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.go),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selected users chips
          if (_selectedUsers.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedUsers
                    .map((user) => Chip(
                          avatar: UserAvatar(userId: user.id, radius: 12),
                          label: Text(user.displayName),
                          onDeleted: () => _removeUser(user),
                          deleteIconColor: AppColors.textSecondary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ),
          // Search field
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: context.l10n.searchForPeople,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // Results
          Expanded(
            child: _isSearching
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: UserAvatar(userId: user.id),
                        title: Text(user.displayName,
                            style: AppTextStyles.channelName),
                        subtitle: Text('@${user.username}',
                            style: AppTextStyles.caption),
                        onTap: () => _addUser(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
