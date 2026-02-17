import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/user_thread.dart';
import '../../../domain/repositories/post_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/user_avatar.dart';
import 'threads_bloc.dart';

class ThreadsScreen extends StatefulWidget {
  const ThreadsScreen({super.key});

  @override
  State<ThreadsScreen> createState() => _ThreadsScreenState();
}

class _ThreadsScreenState extends State<ThreadsScreen> {
  late final ThreadsBloc _bloc;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _bloc = ThreadsBloc(postRepository: sl<PostRepository>());
    _scrollController = ScrollController()..addListener(_onScroll);
    _load();
  }

  void _load() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _bloc.add(LoadThreads(
        userId: authState.user.id,
        teamId: authState.teamId,
      ));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _bloc.add(const LoadMoreThreads());
    }
  }

  @override
  void dispose() {
    _bloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Threads'),
        ),
        body: BlocBuilder<ThreadsBloc, ThreadsState>(
          builder: (context, state) {
            if (state.isLoading && state.threads.isEmpty) {
              return const LoadingIndicator();
            }
            if (state.error != null && state.threads.isEmpty) {
              return ErrorDisplay(
                message: state.error!,
                onRetry: _load,
              );
            }
            if (state.threads.isEmpty) {
              return const Center(
                child: Text('No threads'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _load(),
              child: ListView.separated(
                controller: _scrollController,
                itemCount:
                    state.threads.length + (state.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == state.threads.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  return _ThreadTile(thread: state.threads[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final UserThread thread;

  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    final post = thread.post;
    final replyLabel = thread.replyCount == 1
        ? '1 reply'
        : '${thread.replyCount} replies';
    final timeLabel = DateFormatter.formatChannelTime(thread.lastReplyAt);

    return ListTile(
      leading: UserAvatar(userId: post.userId, radius: 20),
      title: MarkdownBody(
        data: post.message.length > 200
            ? '${post.message.substring(0, 200)}...'
            : post.message,
        styleSheet: MarkdownStyleSheet(
          p: AppTextStyles.body,
        ),
      ),
      subtitle: Text(
        '$replyLabel · $timeLabel',
        style: AppTextStyles.caption,
      ),
      trailing: thread.hasUnread
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.unreadBadge,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                thread.unreadReplies.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () {
        context.push(RouteNames.threadPath(thread.id));
      },
    );
  }
}
