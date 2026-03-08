import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/channel_member.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/channel_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_display_name.dart';

class ChannelMembersScreen extends StatefulWidget {
  final String channelId;

  const ChannelMembersScreen({super.key, required this.channelId});

  @override
  State<ChannelMembersScreen> createState() => _ChannelMembersScreenState();
}

class _ChannelMembersScreenState extends State<ChannelMembersScreen> {
  List<ChannelMember> _members = [];
  bool _isLoading = true;
  String? _error;
  bool _isCurrentUserAdmin = false;
  static const _perPage = 200;

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
  void initState() {
    super.initState();
    _loadAllMembers();
  }

  Future<void> _loadAllMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final allMembers = <ChannelMember>[];
    int page = 0;

    while (true) {
      final result = await sl<ChannelRepository>().getChannelMembers(
        widget.channelId,
        page: page,
        perPage: _perPage,
      );

      int pageCount = 0;
      final failed = result.fold<bool>(
        (failure) {
          if (allMembers.isEmpty) {
            setState(() {
              _isLoading = false;
              _error = failure.message;
            });
          }
          return true;
        },
        (members) {
          pageCount = members.length;
          allMembers.addAll(members);
          return false;
        },
      );

      if (failed) return;
      if (pageCount == 0) break;
      page++;
    }

    allMembers.sort((a, b) => a.user.displayName
        .toLowerCase()
        .compareTo(b.user.displayName.toLowerCase()));

    final currentId = _currentUserId;
    final isAdmin = allMembers.any(
      (m) => m.user.id == currentId && m.isChannelAdmin,
    );

    setState(() {
      _isLoading = false;
      _members = allMembers;
      _isCurrentUserAdmin = isAdmin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Members${_isLoading ? '' : ' (${_members.length})'}'),
        actions: [
          if (_isCurrentUserAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showInviteDialog,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingIndicator();
    if (_error != null) {
      return ErrorDisplay(message: _error!, onRetry: _loadAllMembers);
    }

    final admins = _members.where((m) => m.isChannelAdmin).toList();
    final others = _members.where((m) => !m.isChannelAdmin).toList();

    return ListView.builder(
      itemCount: _sectionItemCount(admins, others),
      itemBuilder: (context, index) =>
          _buildSectionItem(index, admins, others),
    );
  }

  int _sectionItemCount(
    List<ChannelMember> admins,
    List<ChannelMember> others,
  ) {
    int count = 0;
    if (admins.isNotEmpty) count += 1 + admins.length;
    if (others.isNotEmpty) count += 1 + others.length;
    return count;
  }

  Widget _buildSectionItem(
    int index,
    List<ChannelMember> admins,
    List<ChannelMember> others,
  ) {
    int offset = 0;

    // Admin section
    if (admins.isNotEmpty) {
      if (index == offset) {
        return _buildSectionHeader('Admins');
      }
      offset++;
      if (index < offset + admins.length) {
        return _buildMemberTile(admins[index - offset]);
      }
      offset += admins.length;
    }

    // Others section
    if (others.isNotEmpty) {
      if (index == offset) {
        return _buildSectionHeader('Members');
      }
      offset++;
      if (index < offset + others.length) {
        return _buildMemberTile(others[index - offset]);
      }
      offset += others.length;
    }

    return const SizedBox.shrink();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMemberTile(ChannelMember member) {
    final user = member.user;
    final isMe = user.id == _currentUserId;

    return ListTile(
      leading: UserAvatar(userId: user.id, radius: 20),
      title: UserDisplayName(
        userId: user.id,
        displayName: user.displayName,
        style: AppTextStyles.username,
        fallbackEmoji: user.customStatusEmoji,
      ),
      subtitle: Text(
        '@${user.username}',
        style: AppTextStyles.caption,
      ),
      onTap: () => context.push(RouteNames.userProfilePath(user.id)),
      onLongPress: (_isCurrentUserAdmin && !isMe)
          ? () => _showMemberActions(member)
          : null,
    );
  }

  void _showMemberActions(ChannelMember member) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                member.user.displayName,
                style: AppTextStyles.heading2,
              ),
            ),
            const Divider(height: 1),
            if (member.isChannelAdmin)
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: const Text('Remove Admin'),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateRole(member, schemeAdmin: false);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Make Admin'),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateRole(member, schemeAdmin: true);
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_remove, color: AppColors.error),
              title: const Text(
                'Remove from Channel',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmRemove(member);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateRole(
    ChannelMember member, {
    required bool schemeAdmin,
  }) async {
    final result =
        await sl<ChannelRepository>().updateChannelMemberSchemeRoles(
      widget.channelId,
      member.user.id,
      schemeAdmin: schemeAdmin,
    );
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) => _loadAllMembers(),
    );
  }

  void _confirmRemove(ChannelMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Channel'),
        content: Text(
          'Remove ${member.user.displayName} from channel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeMember(member);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(ChannelMember member) async {
    final result = await sl<ChannelRepository>().removeChannelMember(
      widget.channelId,
      member.user.id,
    );
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) => _loadAllMembers(),
    );
  }

  void _showInviteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InviteUserSheet(
        channelId: widget.channelId,
        teamId: _teamId,
        existingMemberIds: _members.map((m) => m.user.id).toSet(),
        onInvited: _loadAllMembers,
      ),
    );
  }
}

class _InviteUserSheet extends StatefulWidget {
  final String channelId;
  final String teamId;
  final Set<String> existingMemberIds;
  final VoidCallback onInvited;

  const _InviteUserSheet({
    required this.channelId,
    required this.teamId,
    required this.existingMemberIds,
    required this.onInvited,
  });

  @override
  State<_InviteUserSheet> createState() => _InviteUserSheetState();
}

class _InviteUserSheetState extends State<_InviteUserSheet> {
  final _searchController = TextEditingController();
  List<User> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    final result = await sl<UserRepository>().autocompleteUsers(
      query,
      teamId: widget.teamId,
    );
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _results = [];
        _isSearching = false;
      }),
      (users) => setState(() {
        _results = users
            .where((u) => !widget.existingMemberIds.contains(u.id))
            .toList();
        _isSearching = false;
      }),
    );
  }

  Future<void> _invite(User user) async {
    final result = await sl<ChannelRepository>().addChannelMember(
      widget.channelId,
      user.id,
    );
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName} added')),
        );
        Navigator.pop(context);
        widget.onInvited();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: _search,
              ),
            ),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return ListTile(
                      leading: UserAvatar(userId: user.id, radius: 20),
                      title: UserDisplayName(
                        userId: user.id,
                        displayName: user.displayName,
                        style: AppTextStyles.username,
                        fallbackEmoji: user.customStatusEmoji,
                      ),
                      subtitle: Text(
                        '@${user.username}',
                        style: AppTextStyles.caption,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add,
                            color: AppColors.accent),
                        onPressed: () => _invite(user),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
