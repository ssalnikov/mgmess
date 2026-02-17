import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/repositories/post_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/websocket/websocket_bloc.dart';
import '../../widgets/loading_indicator.dart';
import 'chat_bloc.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  final String channelId;
  final String channelName;
  final String? initialDraft;

  const ChatScreen({
    super.key,
    required this.channelId,
    this.channelName = '',
    this.initialDraft,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatBloc _chatBloc;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc(postRepository: sl<PostRepository>());
    _chatBloc.add(LoadPosts(channelId: widget.channelId));

    try {
      final wsBloc = context.read<WebSocketBloc>();
      _chatBloc.subscribeToWs(wsBloc.wsEvents);
    } catch (_) {}

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _chatBloc.add(const LoadMorePosts());
    }
  }

  @override
  void dispose() {
    _chatBloc.close();
    _scrollController.dispose();
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
      value: _chatBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.channelName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state.isLoading && state.posts.isEmpty) {
                    return const LoadingIndicator(
                        message: 'Loading messages...');
                  }
                  return _buildMessageList(state);
                },
              ),
            ),
            _buildTypingIndicator(),
            MessageInput(
              channelId: widget.channelId,
              channelName: widget.channelName,
              initialDraft: widget.initialDraft,
              onSend: (message, {fileIds}) {
                _chatBloc.add(SendMessage(
                  message: message,
                  fileIds: fileIds,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatState state) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.posts.length) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final post = state.posts[index];
        final isOwn = post.userId == _currentUserId;
        final showAvatar = !isOwn &&
            (index == state.posts.length - 1 ||
                state.posts[index + 1].userId != post.userId);

        return MessageBubble(
          post: post,
          isOwn: isOwn,
          showAvatar: showAvatar,
          onThreadTap: (postId) =>
              context.push(RouteNames.threadPath(postId)),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (prev, curr) =>
          prev.typingUsers != curr.typingUsers,
      builder: (context, state) {
        if (state.typingUsers.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            '${state.typingUsers.length} typing...',
            style: AppTextStyles.caption.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      },
    );
  }
}

