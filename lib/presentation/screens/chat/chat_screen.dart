import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_stats.dart';
import '../../../domain/entities/user.dart';
import '../../../core/error/failures.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/post.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event.dart';
import '../../blocs/user_status/user_status_cubit.dart';
import '../../blocs/websocket/websocket_bloc.dart';
import '../../utils/forward_helper.dart';
import 'widgets/message_skeleton.dart';
import '../../widgets/swipe_back_wrapper.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_display_name.dart';
import 'chat_bloc.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';
import 'widgets/new_messages_indicator.dart';
import 'widgets/pinned_messages_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String channelId;
  final String channelName;
  final String? initialDraft;
  final int lastViewedAt;
  final String? dmUserId;
  final String? scrollToPostId;

  const ChatScreen({
    super.key,
    required this.channelId,
    this.channelName = '',
    this.initialDraft,
    this.lastViewedAt = 0,
    this.dmUserId,
    this.scrollToPostId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatBloc _chatBloc;
  NotificationBloc? _notificationBloc;
  final _scrollController = ScrollController();
  final _messageInputKey = GlobalKey<MessageInputState>();
  bool _isUserScrolledUp = false;
  int? _memberCount;
  String _channelName = '';
  bool _canPost = true;
  Post? _forwardingPost;
  String? _forwardTargetChannelId;
  bool _markedAsUnread = false;

  @override
  void initState() {
    super.initState();
    _channelName = widget.channelName;
    _chatBloc = ChatBloc(
      postRepository: currentSession.postRepository,
      wsPostParser: currentSession.wsPostParser,
      userId: _currentUserId,
    );
    if (widget.lastViewedAt > 0) {
      _chatBloc.add(SetLastViewedAt(lastViewedAt: widget.lastViewedAt));
    }
    _chatBloc.add(LoadPosts(channelId: widget.channelId));

    if (widget.scrollToPostId != null) {
      _chatBloc.stream.firstWhere((s) => !s.isLoading && s.posts.isNotEmpty).then((_) {
        if (!mounted) return;
        _chatBloc.add(ScrollToMessage(postId: widget.scrollToPostId!));
      });
    }

    try {
      final wsBloc = context.read<WebSocketBloc>();
      _chatBloc.subscribeToWs(wsBloc.wsEvents);
    } catch (_) {}

    try {
      _notificationBloc = context.read<NotificationBloc>();
      _notificationBloc!.add(
        NotificationSetActiveChannel(channelId: widget.channelId),
      );
    } catch (_) {}

    // Notify server immediately so push notifications stop arriving
    final userId = _currentUserId;
    if (userId.isNotEmpty) {
      currentSession.channelRepository.viewChannel(userId, widget.channelId);
    }

    _scrollController.addListener(_onScroll);

    // Load channel metadata in parallel, apply with single setState
    _loadChannelMetadata();
  }

  Future<void> _loadChannelMetadata() async {
    final channelRepo = currentSession.channelRepository;
    final userId = _currentUserId;

    // Launch all requests in parallel
    Future<Either<Failure, Channel>>? channelFuture;
    Future<Either<Failure, ChannelStats>>? statsFuture;
    Future<Either<Failure, List<User>>>? dmUserFuture;
    Future<Either<Failure, bool>>? canPostFuture;

    if (_channelName.isEmpty) {
      channelFuture = channelRepo.getChannel(widget.channelId);
    }
    if (widget.dmUserId == null) {
      statsFuture = channelRepo.getChannelStats(widget.channelId);
    } else {
      dmUserFuture = currentSession.userRepository.getUsersByIds([widget.dmUserId!]);
    }
    if (userId.isNotEmpty) {
      canPostFuture = channelRepo.canUserPost(widget.channelId, userId);
    }

    final results = await Future.wait([
      ?channelFuture,
      ?statsFuture,
      ?dmUserFuture,
      ?canPostFuture,
    ]);

    if (!mounted) return;

    String? newChannelName;
    int? newMemberCount;
    bool? newCanPost;

    for (final result in results) {
      result.fold((_) {}, (value) {
        switch (value) {
          case final Channel channel:
            newChannelName = channel.displayName;
          case final ChannelStats stats:
            newMemberCount = stats.memberCount;
          case final List<User> users:
            if (users.isNotEmpty) {
              context
                  .read<UserStatusCubit>()
                  .setCustomStatusFromUser(users.first);
            }
          case final bool canPost:
            if (canPost != _canPost) newCanPost = canPost;
        }
      });
    }

    if (newChannelName != null || newMemberCount != null || newCanPost != null) {
      setState(() {
        if (newChannelName != null) _channelName = newChannelName!;
        if (newMemberCount != null) _memberCount = newMemberCount;
        if (newCanPost != null) _canPost = newCanPost!;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _chatBloc.add(const LoadMorePosts());
    }

    final scrolledUp = _scrollController.position.pixels > 200;
    if (scrolledUp != _isUserScrolledUp) {
      setState(() => _isUserScrolledUp = scrolledUp);
      if (!scrolledUp) {
        _chatBloc.add(const ClearNewMessages());
      }
    }
  }

  void _openChannelInfo() {
    if (widget.dmUserId != null) {
      context.push(RouteNames.userProfilePath(widget.dmUserId!));
    } else {
      context.push(
        RouteNames.channelInfoPath(widget.channelId),
        extra: {'channelName': _channelName},
      );
    }
  }

  void _showPinnedMessages() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PinnedMessagesSheet(
        channelId: widget.channelId,
        onPostTap: (post) {
          Navigator.of(context).pop();
          if (post.rootId.isNotEmpty) {
            context.push(RouteNames.threadPath(post.rootId));
          } else {
            _chatBloc.add(ScrollToMessage(postId: post.id));
          }
        },
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2015),
      lastDate: now,
    );
    if (picked == null || !mounted) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    // Get channel URL-safe name
    final channelResult =
        await currentSession.channelRepository.getChannel(widget.channelId);
    final channelName = channelResult.fold((_) => null, (c) => c.name);
    if (channelName == null || !mounted) return;

    _chatBloc.add(JumpToDate(
      date: picked,
      teamId: authState.teamId,
      channelUrlName: channelName,
    ));
  }

  void _sendForward(String userMessage) {
    final post = _forwardingPost!;
    final channelId = _forwardTargetChannelId!;

    setState(() {
      _forwardingPost = null;
      _forwardTargetChannelId = null;
    });

    ForwardHelper.sendForward(
      context,
      post: post,
      targetChannelId: channelId,
      userMessage: userMessage,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _chatBloc.add(const ClearNewMessages());
  }

  @override
  void dispose() {
    _notificationBloc?.add(const NotificationClearActiveChannel());

    if (!_markedAsUnread) {
      final userId = _chatBloc.userId;
      final channelId = widget.channelId;
      if (userId.isNotEmpty) {
        currentSession.channelRepository.viewChannel(userId, channelId);
      }
    }

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
      child: SwipeBackWrapper(
        onSwipeBack: () => context.go(RouteNames.channels),
        child: Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: GestureDetector(
              onTap: _openChannelInfo,
              behavior: HitTestBehavior.opaque,
              child: widget.dmUserId != null
                  ? Row(
                      children: [
                        UserAvatar(
                          userId: widget.dmUserId!,
                          radius: 16,
                          heroTag: 'channel_avatar_${widget.channelId}',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: UserDisplayName(
                            userId: widget.dmUserId!,
                            displayName: _channelName,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _channelName,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_memberCount != null)
                          Text(
                            context.l10n.membersCount(_memberCount!),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(RouteNames.channels),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                tooltip: context.l10n.jumpToDate,
                onPressed: _showDatePicker,
              ),
              IconButton(
                icon: const Icon(Icons.push_pin_outlined),
                tooltip: context.l10n.pinnedMessages,
                onPressed: _showPinnedMessages,
              ),
            ],
          ),
          body: MultiBlocListener(
            listeners: [
              BlocListener<ChatBloc, ChatState>(
                listenWhen: (prev, curr) =>
                    prev.error != curr.error && curr.error != null,
                listener: (context, state) {
                  final msg = state.error == 'no_messages_on_date'
                      ? context.l10n.noMessagesOnDate
                      : state.error!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                },
              ),
              BlocListener<ChatBloc, ChatState>(
                listenWhen: (prev, curr) =>
                    prev.highlightedPostId != curr.highlightedPostId &&
                    curr.highlightedPostId != null,
                listener: (context, state) {
                  // Scroll to the highlighted post
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final index = state.posts.indexWhere(
                        (p) => p.id == state.highlightedPostId);
                    if (index >= 0 && _scrollController.hasClients) {
                      final offset = index * 80.0;
                      _scrollController.animateTo(
                        offset,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                  // Clear highlight after 3 seconds
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      _chatBloc.add(const ClearHighlight());
                    }
                  });
                },
              ),
            ],
            child: Column(
              children: [
                Expanded(
                  child: BlocBuilder<ChatBloc, ChatState>(
                    buildWhen: (prev, curr) =>
                        prev.posts != curr.posts ||
                        prev.isLoading != curr.isLoading ||
                        prev.isLoadingMore != curr.isLoadingMore ||
                        prev.hasMore != curr.hasMore ||
                        prev.firstUnreadId != curr.firstUnreadId ||
                        prev.newMessagesCount != curr.newMessagesCount ||
                        prev.highlightedPostId != curr.highlightedPostId,
                    builder: (context, state) {
                      if (state.isLoading && state.posts.isEmpty) {
                        return const MessageSkeletonList();
                      }
                      return Stack(
                        children: [
                          _buildMessageList(state),
                          if (_isUserScrolledUp && state.newMessagesCount > 0)
                            NewMessagesIndicator(
                              count: state.newMessagesCount,
                              onTap: _scrollToBottom,
                            ),
                          if (_isUserScrolledUp && state.newMessagesCount == 0)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton.small(
                                heroTag: 'scroll_to_bottom',
                                onPressed: _scrollToBottom,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                elevation: 4,
                                child: Icon(
                                  Icons.arrow_downward,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                _buildTypingIndicator(),
                if (_canPost)
                  BlocBuilder<ChatBloc, ChatState>(
                    buildWhen: (prev, curr) =>
                        prev.editingPost != curr.editingPost,
                    builder: (context, state) {
                      return MessageInput(
                        key: _messageInputKey,
                        channelId: widget.channelId,
                        channelName: _channelName,
                        initialDraft: widget.initialDraft,
                        editingPost: state.editingPost,
                        forwardingPost: _forwardingPost,
                        onCancelForward: () {
                          setState(() {
                            _forwardingPost = null;
                            _forwardTargetChannelId = null;
                          });
                        },
                        onCancelEdit: () {
                          _chatBloc.add(const CancelEditMessage());
                        },
                        onSaveEdit: (postId, message) {
                          _chatBloc.add(EditMessage(
                            postId: postId,
                            message: message,
                          ));
                        },
                        onSend: (message, {fileIds, priority}) {
                          if (_forwardingPost != null) {
                            _sendForward(message);
                            return;
                          }
                          _chatBloc.add(SendMessage(
                            message: message,
                            fileIds: fileIds,
                            priority: priority,
                          ));
                        },
                      );
                    },
                  )
                else
                  _buildReadOnlyBanner(),
              ],
            ),
          ),
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

        final showDateSeparator = _needsDateSeparator(state.posts, index);
        final showUnreadSeparator =
            state.firstUnreadId != null && post.id == state.firstUnreadId;

        return RepaintBoundary(
          child: Column(
            children: [
              if (showDateSeparator)
                _buildDateSeparator(post.createAt),
              if (showUnreadSeparator) _buildUnreadSeparator(),
              MessageBubble(
                post: post,
                isOwn: isOwn,
                showAvatar: showAvatar,
                isHighlighted: post.id == state.highlightedPostId,
                currentUserId: _currentUserId,
                canPost: _canPost,
                onThreadTap: (postId) =>
                    context.push(RouteNames.threadPath(postId)),
                onQuote: (post) {
                  _messageInputKey.currentState?.insertQuote(post.message);
                },
                onForward: (post) async {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    final channel = await ForwardHelper.pickForwardChannel(
                      context,
                      userId: authState.user.id,
                      teamId: authState.teamId,
                      excludeChannelId: widget.channelId,
                    );
                    if (channel != null && mounted) {
                      setState(() {
                        _forwardingPost = post;
                        _forwardTargetChannelId = channel.id;
                      });
                      _messageInputKey.currentState?.focusInput();
                    }
                  }
                },
                onEdit: (post) {
                  _chatBloc.add(StartEditMessage(post: post));
                },
                onDelete: (post) => _confirmDelete(context, post),
                onMarkUnread: (post) {
                  _markedAsUnread = true;
                  final userId = _currentUserId;
                  if (userId.isNotEmpty) {
                    currentSession.channelRepository.setUnread(
                      userId,
                      post.id,
                    );
                  }
                  context.go(RouteNames.channels);
                },
                onPin: (post) =>
                    _chatBloc.add(PinMessage(postId: post.id)),
                onUnpin: (post) =>
                    _chatBloc.add(UnpinMessage(postId: post.id)),
                onAddReaction: (post, emoji) =>
                    _chatBloc.add(AddReaction(postId: post.id, emojiName: emoji)),
                onRemoveReaction: (post, emoji) =>
                    _chatBloc.add(RemoveReaction(postId: post.id, emojiName: emoji)),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _needsDateSeparator(List<Post> posts, int index) {
    if (index == posts.length - 1) return true;
    final current = DateTime.fromMillisecondsSinceEpoch(posts[index].createAt);
    final next = DateTime.fromMillisecondsSinceEpoch(posts[index + 1].createAt);
    return current.year != next.year ||
        current.month != next.month ||
        current.day != next.day;
  }

  Widget _buildDateSeparator(int timestampMs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              DateFormatter.formatDateSeparator(timestampMs),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }

  Widget _buildUnreadSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.accent)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              context.l10n.newMessagesLabel,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.accent)),
        ],
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
              _chatBloc.add(DeleteMessage(postId: post.id));
            },
            child: Text(context.l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.readOnlyChannel,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
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
            context.l10n.typingIndicator(state.typingUsers.length),
            style: AppTextStyles.caption.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      },
    );
  }
}
