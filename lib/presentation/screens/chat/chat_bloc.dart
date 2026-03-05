import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/websocket_events.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/repositories/post_repository.dart';
import '../../../domain/services/ws_post_parser.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class LoadPosts extends ChatEvent {
  final String channelId;
  const LoadPosts({required this.channelId});
  @override
  List<Object?> get props => [channelId];
}

class LoadMorePosts extends ChatEvent {
  const LoadMorePosts();
}

class SendMessage extends ChatEvent {
  final String message;
  final String? rootId;
  final List<String>? fileIds;
  final String? priority;
  const SendMessage({
    required this.message,
    this.rootId,
    this.fileIds,
    this.priority,
  });
  @override
  List<Object?> get props => [message, rootId, fileIds, priority];
}

class DeleteMessage extends ChatEvent {
  final String postId;
  const DeleteMessage({required this.postId});
  @override
  List<Object?> get props => [postId];
}

class EditMessage extends ChatEvent {
  final String postId;
  final String message;
  const EditMessage({required this.postId, required this.message});
  @override
  List<Object?> get props => [postId, message];
}

class StartEditMessage extends ChatEvent {
  final Post post;
  const StartEditMessage({required this.post});
  @override
  List<Object?> get props => [post];
}

class CancelEditMessage extends ChatEvent {
  const CancelEditMessage();
}

class SetLastViewedAt extends ChatEvent {
  final int lastViewedAt;
  const SetLastViewedAt({required this.lastViewedAt});
  @override
  List<Object?> get props => [lastViewedAt];
}

class ClearNewMessages extends ChatEvent {
  const ClearNewMessages();
}

class IncrementNewMessages extends ChatEvent {
  const IncrementNewMessages();
}

class PinMessage extends ChatEvent {
  final String postId;
  const PinMessage({required this.postId});
  @override
  List<Object?> get props => [postId];
}

class UnpinMessage extends ChatEvent {
  final String postId;
  const UnpinMessage({required this.postId});
  @override
  List<Object?> get props => [postId];
}

class AddReaction extends ChatEvent {
  final String postId;
  final String emojiName;
  const AddReaction({required this.postId, required this.emojiName});
  @override
  List<Object?> get props => [postId, emojiName];
}

class RemoveReaction extends ChatEvent {
  final String postId;
  final String emojiName;
  const RemoveReaction({required this.postId, required this.emojiName});
  @override
  List<Object?> get props => [postId, emojiName];
}

class ScrollToMessage extends ChatEvent {
  final String postId;
  const ScrollToMessage({required this.postId});
  @override
  List<Object?> get props => [postId];
}

class ClearHighlight extends ChatEvent {
  const ClearHighlight();
}

class ChatWsEvent extends ChatEvent {
  final WsEvent wsEvent;
  const ChatWsEvent({required this.wsEvent});
  @override
  List<Object?> get props => [wsEvent];
}

// State
class ChatState extends Equatable {
  final String channelId;
  final List<Post> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final Set<String> typingUsers;
  final bool isSending;
  final Post? editingPost;
  final int lastViewedAt;
  final int newMessagesCount;
  final String? firstUnreadId;
  final String? highlightedPostId;

  const ChatState({
    this.channelId = '',
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.typingUsers = const {},
    this.isSending = false,
    this.editingPost,
    this.lastViewedAt = 0,
    this.newMessagesCount = 0,
    this.firstUnreadId,
    this.highlightedPostId,
  });

  ChatState copyWith({
    String? channelId,
    List<Post>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    Set<String>? typingUsers,
    bool? isSending,
    Post? editingPost,
    bool clearEditingPost = false,
    int? lastViewedAt,
    int? newMessagesCount,
    String? firstUnreadId,
    bool clearFirstUnreadId = false,
    String? highlightedPostId,
    bool clearHighlightedPostId = false,
  }) {
    return ChatState(
      channelId: channelId ?? this.channelId,
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      typingUsers: typingUsers ?? this.typingUsers,
      isSending: isSending ?? this.isSending,
      editingPost: clearEditingPost ? null : (editingPost ?? this.editingPost),
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      newMessagesCount: newMessagesCount ?? this.newMessagesCount,
      firstUnreadId: clearFirstUnreadId ? null : (firstUnreadId ?? this.firstUnreadId),
      highlightedPostId: clearHighlightedPostId ? null : (highlightedPostId ?? this.highlightedPostId),
    );
  }

  @override
  List<Object?> get props => [
        channelId,
        posts,
        isLoading,
        isLoadingMore,
        hasMore,
        error,
        typingUsers,
        isSending,
        editingPost,
        lastViewedAt,
        newMessagesCount,
        firstUnreadId,
        highlightedPostId,
      ];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final PostRepository _postRepository;
  final WsPostParser _wsPostParser;
  final String userId;
  StreamSubscription<WsEvent>? _wsSub;
  Timer? _typingTimer;

  ChatBloc({
    required PostRepository postRepository,
    required WsPostParser wsPostParser,
    required this.userId,
  })  : _postRepository = postRepository,
        _wsPostParser = wsPostParser,
        super(const ChatState()) {
    on<LoadPosts>(_onLoadPosts);
    on<LoadMorePosts>(_onLoadMorePosts);
    on<SendMessage>(_onSendMessage);
    on<EditMessage>(_onEditMessage);
    on<StartEditMessage>(_onStartEditMessage);
    on<CancelEditMessage>(_onCancelEditMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<SetLastViewedAt>(_onSetLastViewedAt);
    on<ClearNewMessages>(_onClearNewMessages);
    on<IncrementNewMessages>(_onIncrementNewMessages);
    on<PinMessage>(_onPinMessage);
    on<UnpinMessage>(_onUnpinMessage);
    on<AddReaction>(_onAddReaction);
    on<RemoveReaction>(_onRemoveReaction);
    on<ScrollToMessage>(_onScrollToMessage);
    on<ClearHighlight>(_onClearHighlight);
    on<ChatWsEvent>(_onWsEvent);
  }

  void subscribeToWs(Stream<WsEvent> wsEvents) {
    _wsSub?.cancel();
    _wsSub = wsEvents
        .where((e) =>
            e.channelId == state.channelId &&
            (e.event == WsEventType.posted ||
                e.event == WsEventType.postEdited ||
                e.event == WsEventType.postDeleted ||
                e.event == WsEventType.typing ||
                e.event == WsEventType.reactionAdded ||
                e.event == WsEventType.reactionRemoved ||
                e.event == WsEventType.channelViewed))
        .listen((event) => add(ChatWsEvent(wsEvent: event)));
  }

  Future<void> _onLoadPosts(
    LoadPosts event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(
      channelId: event.channelId,
      isLoading: true,
    ));

    final result = await _postRepository.getChannelPosts(
      event.channelId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (posts) {
        final rootPosts = _filterAndCountReplies(posts);
        // Determine firstUnreadId
        String? unreadId;
        if (state.lastViewedAt > 0) {
          // Posts are sorted newest first; find the first (oldest) post with createAt > lastViewedAt
          for (int i = rootPosts.length - 1; i >= 0; i--) {
            if (rootPosts[i].createAt > state.lastViewedAt) {
              unreadId = rootPosts[i].id;
              break;
            }
          }
        }
        emit(state.copyWith(
          posts: rootPosts,
          isLoading: false,
          hasMore: posts.length >= 60,
          firstUnreadId: unreadId,
        ));
      },
    );
  }

  Future<void> _onLoadMorePosts(
    LoadMorePosts event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore || state.posts.isEmpty) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));
    final oldestId = state.posts.last.id;

    final result = await _postRepository.getChannelPosts(
      state.channelId,
      before: oldestId,
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoadingMore: false)),
      (newPosts) {
        final newRootPosts = _filterAndCountReplies(newPosts);
        emit(state.copyWith(
          posts: [...state.posts, ...newRootPosts],
          isLoadingMore: false,
          hasMore: newPosts.length >= 60,
        ));
      },
    );
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isSending: true));

    final result = await _postRepository.createPost(
      channelId: state.channelId,
      message: event.message,
      rootId: event.rootId,
      fileIds: event.fileIds,
      priority: event.priority,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSending: false,
        error: failure.message,
      )),
      (post) {
        // Post may have already arrived via WS before HTTP response
        if (state.posts.any((p) => p.id == post.id)) {
          emit(state.copyWith(isSending: false));
        } else {
          emit(state.copyWith(
            isSending: false,
            posts: [post, ...state.posts],
          ));
        }
      },
    );
  }

  Future<void> _onEditMessage(
    EditMessage event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _postRepository.editPost(event.postId, event.message);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (editedPost) {
        final posts = state.posts.map((p) {
          if (p.id == editedPost.id) return editedPost;
          return p;
        }).toList();
        emit(state.copyWith(posts: posts, clearEditingPost: true));
      },
    );
  }

  void _onStartEditMessage(
    StartEditMessage event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(editingPost: event.post));
  }

  void _onCancelEditMessage(
    CancelEditMessage event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(clearEditingPost: true));
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _postRepository.deletePost(event.postId);
    result.fold(
      (_) {},
      (_) {
        final posts =
            state.posts.where((p) => p.id != event.postId).toList();
        emit(state.copyWith(posts: posts));
      },
    );
  }

  void _onSetLastViewedAt(
    SetLastViewedAt event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(lastViewedAt: event.lastViewedAt));
  }

  void _onClearNewMessages(
    ClearNewMessages event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(
      newMessagesCount: 0,
      clearFirstUnreadId: true,
    ));
  }

  void _onIncrementNewMessages(
    IncrementNewMessages event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(
      newMessagesCount: state.newMessagesCount + 1,
    ));
  }

  Future<void> _onPinMessage(
    PinMessage event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _postRepository.pinPost(event.postId);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        final posts = state.posts.map((p) {
          if (p.id == event.postId) return p.copyWith(isPinned: true);
          return p;
        }).toList();
        emit(state.copyWith(posts: posts));
      },
    );
  }

  Future<void> _onUnpinMessage(
    UnpinMessage event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _postRepository.unpinPost(event.postId);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        final posts = state.posts.map((p) {
          if (p.id == event.postId) return p.copyWith(isPinned: false);
          return p;
        }).toList();
        emit(state.copyWith(posts: posts));
      },
    );
  }

  Future<void> _onAddReaction(
    AddReaction event,
    Emitter<ChatState> emit,
  ) async {
    // Optimistic update
    final posts = state.posts.map((p) {
      if (p.id == event.postId) {
        final reactions = Map<String, List<String>>.from(
          p.reactions.map((k, v) => MapEntry(k, List<String>.from(v))),
        );
        reactions.putIfAbsent(event.emojiName, () => []);
        if (!reactions[event.emojiName]!.contains(userId)) {
          reactions[event.emojiName]!.add(userId);
        }
        return p.copyWith(reactions: reactions);
      }
      return p;
    }).toList();
    emit(state.copyWith(posts: posts));

    final result = await _postRepository.addReaction(
      event.postId, userId, event.emojiName,
    );
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {},
    );
  }

  Future<void> _onRemoveReaction(
    RemoveReaction event,
    Emitter<ChatState> emit,
  ) async {
    // Optimistic update
    final posts = state.posts.map((p) {
      if (p.id == event.postId) {
        final reactions = Map<String, List<String>>.from(
          p.reactions.map((k, v) => MapEntry(k, List<String>.from(v))),
        );
        reactions[event.emojiName]?.remove(userId);
        if (reactions[event.emojiName]?.isEmpty ?? false) {
          reactions.remove(event.emojiName);
        }
        return p.copyWith(reactions: reactions);
      }
      return p;
    }).toList();
    emit(state.copyWith(posts: posts));

    final result = await _postRepository.removeReaction(
      event.postId, userId, event.emojiName,
    );
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {},
    );
  }

  Future<void> _onScrollToMessage(
    ScrollToMessage event,
    Emitter<ChatState> emit,
  ) async {
    // If post is already loaded, just highlight it
    if (state.posts.any((p) => p.id == event.postId)) {
      emit(state.copyWith(highlightedPostId: event.postId));
      return;
    }

    // Load posts around the target post
    emit(state.copyWith(isLoading: true));

    final postResult = await _postRepository.getPost(event.postId);
    await postResult.fold(
      (failure) async {
        emit(state.copyWith(
          isLoading: false,
          error: failure.message,
        ));
      },
      (targetPost) async {
        // Load posts before and after
        final beforeResult = await _postRepository.getChannelPosts(
          state.channelId,
          after: event.postId,
          perPage: 30,
        );
        final afterResult = await _postRepository.getChannelPosts(
          state.channelId,
          before: event.postId,
          perPage: 30,
        );

        final allPosts = <Post>[targetPost];
        beforeResult.fold((_) {}, (posts) => allPosts.addAll(posts));
        afterResult.fold((_) {}, (posts) => allPosts.addAll(posts));

        // Deduplicate and sort by createAt descending (newest first)
        final seen = <String>{};
        final unique = <Post>[];
        for (final p in allPosts) {
          if (seen.add(p.id)) unique.add(p);
        }
        unique.sort((a, b) => b.createAt.compareTo(a.createAt));

        final rootPosts = _filterAndCountReplies(unique);

        emit(state.copyWith(
          posts: rootPosts,
          isLoading: false,
          highlightedPostId: event.postId,
          hasMore: true,
        ));
      },
    );
  }

  void _onClearHighlight(
    ClearHighlight event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(clearHighlightedPostId: true));
  }

  void _onWsEvent(ChatWsEvent event, Emitter<ChatState> emit) {
    final wsEvent = event.wsEvent;
    switch (wsEvent.event) {
      case WsEventType.posted:
        _handleNewPost(wsEvent, emit);
      case WsEventType.postEdited:
        _handlePostEdited(wsEvent, emit);
      case WsEventType.postDeleted:
        _handlePostDeleted(wsEvent, emit);
      case WsEventType.reactionAdded:
        _handleReactionAdded(wsEvent, emit);
      case WsEventType.reactionRemoved:
        _handleReactionRemoved(wsEvent, emit);
      case WsEventType.channelViewed:
        _handleChannelViewed(wsEvent, emit);
      case WsEventType.typing:
      case '_clear_typing':
        _handleTyping(wsEvent, emit);
      default:
        break;
    }
  }

  void _handleNewPost(WsEvent wsEvent, Emitter<ChatState> emit) {
    final postJson = wsEvent.data['post'];
    if (postJson is! String) return;

    final post = _wsPostParser.parsePost(postJson);
    if (post == null) return;

    if (post.isReply) {
      // Update root post's reply count
      final posts = state.posts.map((p) {
        if (p.id == post.rootId) {
          return p.copyWith(replyCount: p.replyCount + 1);
        }
        return p;
      }).toList();
      emit(state.copyWith(posts: posts));
      return;
    }
    // Avoid duplicates (from optimistic send)
    if (state.posts.any((p) => p.id == post.id)) return;

    final isOwnPost = post.userId == userId;
    emit(state.copyWith(
      posts: [post, ...state.posts],
      newMessagesCount: isOwnPost
          ? state.newMessagesCount
          : state.newMessagesCount + 1,
    ));
  }

  void _handleChannelViewed(WsEvent wsEvent, Emitter<ChatState> emit) {
    emit(state.copyWith(
      newMessagesCount: 0,
      clearFirstUnreadId: true,
    ));
  }

  void _handlePostEdited(WsEvent wsEvent, Emitter<ChatState> emit) {
    final postJson = wsEvent.data['post'];
    if (postJson is! String) return;

    final edited = _wsPostParser.parsePost(postJson);
    if (edited == null) return;

    final posts = state.posts.map((p) {
      if (p.id == edited.id) return edited;
      return p;
    }).toList();
    emit(state.copyWith(posts: posts));
  }

  void _handlePostDeleted(WsEvent wsEvent, Emitter<ChatState> emit) {
    final postJson = wsEvent.data['post'];
    if (postJson is String) {
      try {
        final deleted = jsonDecode(postJson) as Map<String, dynamic>;
        final postId = deleted['id'] as String?;
        final rootId = deleted['root_id'] as String? ?? '';
        if (postId == null) return;
        if (rootId.isNotEmpty) {
          // Reply deleted — decrement root post's reply count
          final posts = state.posts.map((p) {
            if (p.id == rootId && p.replyCount > 0) {
              return p.copyWith(replyCount: p.replyCount - 1);
            }
            return p;
          }).toList();
          emit(state.copyWith(posts: posts));
        } else {
          final posts = state.posts.where((p) => p.id != postId).toList();
          emit(state.copyWith(posts: posts));
        }
      } catch (_) {}
    }
  }

  void _handleReactionAdded(WsEvent wsEvent, Emitter<ChatState> emit) {
    final reactionJson = wsEvent.data['reaction'];
    if (reactionJson is! String) return;
    try {
      final reaction = jsonDecode(reactionJson) as Map<String, dynamic>;
      final postId = reaction['post_id'] as String? ?? '';
      final emojiName = reaction['emoji_name'] as String? ?? '';
      final reactUserId = reaction['user_id'] as String? ?? '';
      if (postId.isEmpty || emojiName.isEmpty) return;

      final posts = state.posts.map((p) {
        if (p.id == postId) {
          final reactions = Map<String, List<String>>.from(
            p.reactions.map((k, v) => MapEntry(k, List<String>.from(v))),
          );
          reactions.putIfAbsent(emojiName, () => []);
          if (!reactions[emojiName]!.contains(reactUserId)) {
            reactions[emojiName]!.add(reactUserId);
          }
          return p.copyWith(reactions: reactions);
        }
        return p;
      }).toList();
      emit(state.copyWith(posts: posts));
    } catch (_) {}
  }

  void _handleReactionRemoved(WsEvent wsEvent, Emitter<ChatState> emit) {
    final reactionJson = wsEvent.data['reaction'];
    if (reactionJson is! String) return;
    try {
      final reaction = jsonDecode(reactionJson) as Map<String, dynamic>;
      final postId = reaction['post_id'] as String? ?? '';
      final emojiName = reaction['emoji_name'] as String? ?? '';
      final reactUserId = reaction['user_id'] as String? ?? '';
      if (postId.isEmpty || emojiName.isEmpty) return;

      final posts = state.posts.map((p) {
        if (p.id == postId) {
          final reactions = Map<String, List<String>>.from(
            p.reactions.map((k, v) => MapEntry(k, List<String>.from(v))),
          );
          reactions[emojiName]?.remove(reactUserId);
          if (reactions[emojiName]?.isEmpty ?? false) {
            reactions.remove(emojiName);
          }
          return p.copyWith(reactions: reactions);
        }
        return p;
      }).toList();
      emit(state.copyWith(posts: posts));
    } catch (_) {}
  }

  void _handleTyping(WsEvent wsEvent, Emitter<ChatState> emit) {
    final userId = wsEvent.userId;
    if (userId == null) return;

    if (wsEvent.event == '_clear_typing') {
      emit(state.copyWith(typingUsers: const {}));
      return;
    }

    final typingUsers = {...state.typingUsers, userId};
    emit(state.copyWith(typingUsers: typingUsers));

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 5), () {
      add(const ChatWsEvent(
        wsEvent: WsEvent(event: '_clear_typing', data: {}),
      ));
    });
  }

  /// Filters out replies and computes accurate replyCount for root posts
  /// by counting replies visible in the response.
  List<Post> _filterAndCountReplies(List<Post> posts) {
    final replyCounts = <String, int>{};
    for (final p in posts) {
      if (p.isReply) {
        replyCounts[p.rootId] = (replyCounts[p.rootId] ?? 0) + 1;
      }
    }
    return posts.where((p) => !p.isReply).map((p) {
      final counted = replyCounts[p.id] ?? 0;
      final best = p.replyCount >= counted ? p.replyCount : counted;
      return best != p.replyCount ? p.copyWith(replyCount: best) : p;
    }).toList();
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    _typingTimer?.cancel();
    return super.close();
  }
}
