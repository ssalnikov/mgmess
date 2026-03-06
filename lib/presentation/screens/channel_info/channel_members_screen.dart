import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/channel_member.dart';
import '../../../domain/repositories/channel_repository.dart';
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
  final List<ChannelMember> _members = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 0;
  static const _perPage = 60;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 0;
      _members.clear();
    });

    final result = await sl<ChannelRepository>().getChannelMembers(
      widget.channelId,
      page: 0,
      perPage: _perPage,
    );

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _error = failure.message;
      }),
      (members) => setState(() {
        _isLoading = false;
        _members.addAll(members);
        _hasMore = members.length >= _perPage;
      }),
    );
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    _page++;
    final result = await sl<ChannelRepository>().getChannelMembers(
      widget.channelId,
      page: _page,
      perPage: _perPage,
    );

    result.fold(
      (failure) => setState(() {
        _isLoadingMore = false;
        _page--;
      }),
      (members) => setState(() {
        _isLoadingMore = false;
        _members.addAll(members);
        _hasMore = members.length >= _perPage;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Участники'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingIndicator();
    if (_error != null) {
      return ErrorDisplay(message: _error!, onRetry: _loadMembers);
    }

    final admins = _members.where((m) => m.isChannelAdmin).toList();
    final others = _members.where((m) => !m.isChannelAdmin).toList();

    return ListView.builder(
      controller: _scrollController,
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
    if (admins.isNotEmpty) {
      count += 1 + admins.length; // header + items
    }
    if (others.isNotEmpty) {
      count += 1 + others.length; // header + items
    }
    if (_isLoadingMore) count += 1;
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
        return _buildSectionHeader('Администраторы');
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
        return _buildSectionHeader('Участники');
      }
      offset++;
      if (index < offset + others.length) {
        return _buildMemberTile(others[index - offset]);
      }
      offset += others.length;
    }

    // Loading indicator
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
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
    );
  }
}
