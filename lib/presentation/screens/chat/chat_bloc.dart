import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/websocket_events.dart';
import '../../../data/models/post_model.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/repositories/post_repository.dart';

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
  const SendMessage({
    required this.message,
    this.rootId,
    this.fileIds,
  });
  @override
  List<Object?> get props => [message, rootId, fileIds];
}

class DeleteMessage extends ChatEvent {
  final String postId;
  const DeleteMessage({required this.postId});
  @override
  List<Object?> get props => [postId];
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

  const ChatState({
    this.channelId = '',
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.typingUsers = const {},
    this.isSending = false,
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
      ];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final PostRepository _postRepository;
  StreamSubscription<WsEvent>? _wsSub;
  Timer? _typingTimer;

  ChatBloc({required PostRepository postRepository})
      : _postRepository = postRepository,
        super(const ChatState()) {
    on<LoadPosts>(_onLoadPosts);
    on<LoadMorePosts>(_onLoadMorePosts);
    on<SendMessage>(_onSendMessage);
    on<DeleteMessage>(_onDeleteMessage);
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
                e.event == WsEventType.typing))
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
        emit(state.copyWith(
          posts: rootPosts,
          isLoading: false,
          hasMore: posts.length >= 60,
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

  void _onWsEvent(ChatWsEvent event, Emitter<ChatState> emit) {
    final wsEvent = event.wsEvent;
    switch (wsEvent.event) {
      case WsEventType.posted:
        _handleNewPost(wsEvent, emit);
      case WsEventType.postEdited:
        _handlePostEdited(wsEvent, emit);
      case WsEventType.postDeleted:
        _handlePostDeleted(wsEvent, emit);
      case WsEventType.typing:
      case '_clear_typing':
        _handleTyping(wsEvent, emit);
      default:
        break;
    }
  }

  void _handleNewPost(WsEvent wsEvent, Emitter<ChatState> emit) {
    final postJson = wsEvent.data['post'];
    if (postJson is String) {
      try {
        final post = PostModel.fromJson(
          jsonDecode(postJson) as Map<String, dynamic>,
        );
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
        emit(state.copyWith(posts: [post, ...state.posts]));
      } catch (_) {}
    }
  }

  void _handlePostEdited(WsEvent wsEvent, Emitter<ChatState> emit) {
    final postJson = wsEvent.data['post'];
    if (postJson is String) {
      try {
        final edited = PostModel.fromJson(
          jsonDecode(postJson) as Map<String, dynamic>,
        );
        final posts = state.posts.map((p) {
          if (p.id == edited.id) return edited;
          return p;
        }).toList();
        emit(state.copyWith(posts: posts));
      } catch (_) {}
    }
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
