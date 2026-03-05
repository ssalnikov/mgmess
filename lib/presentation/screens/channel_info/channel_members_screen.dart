import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/channel_repository.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/user_avatar.dart';

class ChannelMembersScreen extends StatefulWidget {
  final String channelId;

  const ChannelMembersScreen({super.key, required this.channelId});

  @override
  State<ChannelMembersScreen> createState() => _ChannelMembersScreenState();
}

class _ChannelMembersScreenState extends State<ChannelMembersScreen> {
  final List<User> _members = [];
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
      (users) => setState(() {
        _isLoading = false;
        _members.addAll(users);
        _hasMore = users.length >= _perPage;
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
      (users) => setState(() {
        _isLoadingMore = false;
        _members.addAll(users);
        _hasMore = users.length >= _perPage;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingIndicator();
    if (_error != null) {
      return ErrorDisplay(message: _error!, onRetry: _loadMembers);
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _members.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _members.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final user = _members[index];
        return ListTile(
          leading: UserAvatar(userId: user.id, radius: 20),
          title: Text(user.displayName, style: AppTextStyles.username),
          subtitle: Text(
            '@${user.username}',
            style: AppTextStyles.caption,
          ),
          onTap: () => context.push(RouteNames.userProfilePath(user.id)),
        );
      },
    );
  }
}
