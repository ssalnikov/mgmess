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
  List<ChannelMember> _members = [];
  bool _isLoading = true;
  String? _error;
  static const _perPage = 200;

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

    setState(() {
      _isLoading = false;
      _members = allMembers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Участники${_isLoading ? '' : ' (${_members.length})'}'),
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
