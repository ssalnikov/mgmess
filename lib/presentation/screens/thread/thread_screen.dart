import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/repositories/post_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/websocket/websocket_bloc.dart';
import '../../widgets/loading_indicator.dart';
import '../chat/widgets/message_bubble.dart';
import '../chat/widgets/message_input.dart';
import 'thread_bloc.dart';

class ThreadScreen extends StatefulWidget {
  final String postId;

  const ThreadScreen({super.key, required this.postId});

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  late final ThreadBloc _threadBloc;

  @override
  void initState() {
    super.initState();
    _threadBloc = ThreadBloc(postRepository: sl<PostRepository>());
    _threadBloc.add(LoadThread(postId: widget.postId));

    try {
      final wsBloc = context.read<WebSocketBloc>();
      _threadBloc.subscribeToWs(wsBloc.wsEvents);
    } catch (_) {}
  }

  @override
  void dispose() {
    _threadBloc.close();
    super.dispose();
  }

  String get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _threadBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thread'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ThreadBloc, ThreadState>(
                builder: (context, state) {
                  if (state.isLoading && state.posts.isEmpty) {
                    return const LoadingIndicator(
                        message: 'Loading thread...');
                  }
                  if (state.error != null && state.posts.isEmpty) {
                    return Center(
                      child: Text(
                        state.error!,
                        style: AppTextStyles.caption,
                      ),
                    );
                  }
                  return _buildThreadList(state);
                },
              ),
            ),
            BlocBuilder<ThreadBloc, ThreadState>(
              buildWhen: (prev, curr) =>
                  prev.channelId != curr.channelId,
              builder: (context, state) {
                if (state.channelId.isEmpty) {
                  return const SizedBox.shrink();
                }
                return MessageInput(
                  channelId: state.channelId,
                  onSend: (message, {fileIds}) {
                    _threadBloc.add(SendThreadReply(
                      message: message,
                      fileIds: fileIds,
                    ));
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadList(ThreadState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: state.posts.length,
      itemBuilder: (context, index) {
        final post = state.posts[index];
        final isOwn = post.userId == _currentUserId;
        final showAvatar = !isOwn &&
            (index == 0 ||
                state.posts[index - 1].userId != post.userId);
        final isRoot = index == 0;

        return Column(
          children: [
            MessageBubble(
              post: post,
              isOwn: isOwn,
              showAvatar: showAvatar,
            ),
            if (isRoot && state.posts.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${state.posts.length - 1} ${state.posts.length - 1 == 1 ? 'reply' : 'replies'}',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
