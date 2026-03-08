import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/route_names.dart';
import '../../../domain/entities/post.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/repositories/post_repository.dart';
import '../../../domain/services/ws_post_parser.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/websocket/websocket_bloc.dart';
import '../../utils/forward_helper.dart';
import '../chat/widgets/message_skeleton.dart';
import '../../widgets/swipe_back_wrapper.dart';
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
  final _messageInputKey = GlobalKey<MessageInputState>();

  @override
  void initState() {
    super.initState();
    _threadBloc = ThreadBloc(
      postRepository: sl<PostRepository>(),
      wsPostParser: sl<WsPostParser>(),
      userId: _currentUserId,
    );
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

  void _navigateToChannel() {
    final channelId = _threadBloc.state.channelId;
    if (channelId.isNotEmpty) {
      context.go(
        RouteNames.chatPath(channelId),
        extra: <String, dynamic>{
          'scrollToPostId': widget.postId,
        },
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _threadBloc,
      child: SwipeBackWrapper(
        onSwipeBack: _navigateToChannel,
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.thread),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _navigateToChannel,
            ),
          ),
          body: BlocListener<ThreadBloc, ThreadState>(
            listenWhen: (prev, curr) =>
                prev.error != curr.error && curr.error != null,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),
              );
            },
            child: Column(
              children: [
                Expanded(
                  child: BlocBuilder<ThreadBloc, ThreadState>(
                    buildWhen: (prev, curr) =>
                        prev.posts != curr.posts ||
                        prev.isLoading != curr.isLoading ||
                        prev.error != curr.error,
                    builder: (context, state) {
                      if (state.isLoading && state.posts.isEmpty) {
                        return const MessageSkeletonList();
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
                      prev.channelId != curr.channelId ||
                      prev.editingPost != curr.editingPost,
                  builder: (context, state) {
                    if (state.channelId.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return MessageInput(
                      key: _messageInputKey,
                      channelId: state.channelId,
                      editingPost: state.editingPost,
                      onCancelEdit: () {
                        _threadBloc.add(const CancelEditThreadPost());
                      },
                      onSaveEdit: (postId, message) {
                        _threadBloc.add(EditThreadPost(
                          postId: postId,
                          message: message,
                        ));
                      },
                      onSend: (message, {fileIds, priority}) {
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
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteMessageTitle),
        content: Text(context.l10n.deleteMessageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _threadBloc.add(DeleteThreadPost(postId: post.id));
            },
            child: Text(context.l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
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
              currentUserId: _currentUserId,
              onQuote: (post) {
                _messageInputKey.currentState?.insertQuote(post.message);
              },
              onForward: (post) {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  ForwardHelper.forwardPost(
                    context,
                    post: post,
                    userId: authState.user.id,
                    teamId: authState.teamId,
                    teamName: authState.teamName,
                    excludeChannelId: _threadBloc.state.channelId,
                  );
                }
              },
              onEdit: (post) {
                _threadBloc.add(StartEditThreadPost(post: post));
              },
              onDelete: (post) => _confirmDelete(context, post),
              onAddReaction: (post, emoji) =>
                  _threadBloc.add(AddThreadReaction(postId: post.id, emojiName: emoji)),
              onRemoveReaction: (post, emoji) =>
                  _threadBloc.add(RemoveThreadReaction(postId: post.id, emojiName: emoji)),
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
                        context.l10n.repliesCount(state.posts.length - 1),
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
