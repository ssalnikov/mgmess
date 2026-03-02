import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/websocket_events.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/repositories/post_repository.dart';
import '../../../domain/services/ws_post_parser.dart';

// Events
abstract class ThreadEvent extends Equatable {
  const ThreadEvent();
  @override
  List<Object?> get props => [];
}

class LoadThread extends ThreadEvent {
  final String postId;
  const LoadThread({required this.postId});
  @override
  List<Object?> get props => [postId];
}

class SendThreadReply extends ThreadEvent {
  final String message;
  final List<String>? fileIds;
  const SendThreadReply({required this.message, this.fileIds});
  @override
  List<Object?> get props => [message, fileIds];
}

class EditThreadPost extends ThreadEvent {
  final String postId;
  final String message;
  const EditThreadPost({required this.postId, required this.message});
  @override
  List<Object?> get props => [postId, message];
}

class StartEditThreadPost extends ThreadEvent {
  final Post post;
  const StartEditThreadPost({required this.post});
  @override
  List<Object?> get props => [post];
}

class CancelEditThreadPost extends ThreadEvent {
  const CancelEditThreadPost();
}

class DeleteThreadPost extends ThreadEvent {
  final String postId;
  const DeleteThreadPost({required this.postId});
  @override
  List<Object?> get props => [postId];
}

class AddThreadReaction extends ThreadEvent {
  final String postId;
  final String emojiName;
  const AddThreadReaction({required this.postId, required this.emojiName});
  @override
  List<Object?> get props => [postId, emojiName];
}

class RemoveThreadReaction extends ThreadEvent {
  final String postId;
  final String emojiName;
  const RemoveThreadReaction({required this.postId, required this.emojiName});
  @override
  List<Object?> get props => [postId, emojiName];
}

class ThreadWsEvent extends ThreadEvent {
  final WsEvent wsEvent;
  const ThreadWsEvent({required this.wsEvent});
  @override
  List<Object?> get props => [wsEvent];
}

// State
class ThreadState extends Equatable {
  final String rootPostId;
  final String channelId;
  final List<Post> posts;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final Post? editingPost;

  const ThreadState({
    this.rootPostId = '',
    this.channelId = '',
    this.posts = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.editingPost,
  });

  ThreadState copyWith({
    String? rootPostId,
    String? channelId,
    List<Post>? posts,
    bool? isLoading,
    bool? isSending,
    String? error,
    Post? editingPost,
    bool clearEditingPost = false,
  }) {
    return ThreadState(
      rootPostId: rootPostId ?? this.rootPostId,
      channelId: channelId ?? this.channelId,
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
      editingPost: clearEditingPost ? null : (editingPost ?? this.editingPost),
    );
  }

  @override
  List<Object?> get props =>
      [rootPostId, channelId, posts, isLoading, isSending, error, editingPost];
}

// BLoC
class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  final PostRepository _postRepository;
  final WsPostParser _wsPostParser;
  final String userId;
  StreamSubscription<WsEvent>? _wsSub;

  ThreadBloc({
    required PostRepository postRepository,
    required WsPostParser wsPostParser,
    required this.userId,
  })  : _postRepository = postRepository,
        _wsPostParser = wsPostParser,
        super(const ThreadState()) {
    on<LoadThread>(_onLoadThread);
    on<SendThreadReply>(_onSendReply);
    on<EditThreadPost>(_onEditPost);
    on<StartEditThreadPost>(_onStartEditPost);
    on<CancelEditThreadPost>(_onCancelEditPost);
    on<DeleteThreadPost>(_onDeletePost);
    on<AddThreadReaction>(_onAddReaction);
    on<RemoveThreadReaction>(_onRemoveReaction);
    on<ThreadWsEvent>(_onWsEvent);
  }

  void subscribeToWs(Stream<WsEvent> wsEvents) {
    _wsSub?.cancel();
    _wsSub = wsEvents
        .where((e) =>
            e.event == WsEventType.posted ||
            e.event == WsEventType.postEdited ||
            e.event == WsEventType.postDeleted ||
            e.event == WsEventType.reactionAdded ||
            e.event == WsEventType.reactionRemoved)
        .listen((event) => add(ThreadWsEvent(wsEvent: event)));
  }

  Future<void> _onLoadThread(
    LoadThread event,
    Emitter<ThreadState> emit,
  ) async {
    emit(state.copyWith(
      rootPostId: event.postId,
      isLoading: true,
    ));

    final result = await _postRepository.getPostThread(event.postId);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (posts) {
        posts.sort((a, b) => a.createAt.compareTo(b.createAt));
        final channelId = posts.isNotEmpty ? posts.first.channelId : '';
        emit(state.copyWith(
          posts: posts,
          channelId: channelId,
          isLoading: false,
        ));
      },
    );
  }

  Future<void> _onSendReply(
    SendThreadReply event,
    Emitter<ThreadState> emit,
  ) async {
    emit(state.copyWith(isSending: true));

    final result = await _postRepository.createPost(
      channelId: state.channelId,
      message: event.message,
      rootId: state.rootPostId,
      fileIds: event.fileIds,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSending: false,
        error: failure.message,
      )),
      (post) {
        if (state.posts.any((p) => p.id == post.id)) {
          emit(state.copyWith(isSending: false));
        } else {
          emit(state.copyWith(
            isSending: false,
            posts: [...state.posts, post],
          ));
        }
      },
    );
  }

  Future<void> _onEditPost(
    EditThreadPost event,
    Emitter<ThreadState> emit,
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

  void _onStartEditPost(
    StartEditThreadPost event,
    Emitter<ThreadState> emit,
  ) {
    emit(state.copyWith(editingPost: event.post));
  }

  void _onCancelEditPost(
    CancelEditThreadPost event,
    Emitter<ThreadState> emit,
  ) {
    emit(state.copyWith(clearEditingPost: true));
  }

  Future<void> _onDeletePost(
    DeleteThreadPost event,
    Emitter<ThreadState> emit,
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

  Future<void> _onAddReaction(
    AddThreadReaction event,
    Emitter<ThreadState> emit,
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
    RemoveThreadReaction event,
    Emitter<ThreadState> emit,
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

  void _onWsEvent(ThreadWsEvent event, Emitter<ThreadState> emit) {
    final wsEvent = event.wsEvent;

    if (wsEvent.event == WsEventType.reactionAdded ||
        wsEvent.event == WsEventType.reactionRemoved) {
      _handleWsReaction(wsEvent, emit);
      return;
    }

    final postJson = wsEvent.data['post'];
    if (postJson is! String) return;

    switch (wsEvent.event) {
      case WsEventType.posted:
        final post = _wsPostParser.parsePost(postJson);
        if (post == null) return;
        if (post.rootId != state.rootPostId &&
            post.id != state.rootPostId) {
          return;
        }
        if (state.posts.any((p) => p.id == post.id)) return;
        emit(state.copyWith(posts: [...state.posts, post]));

      case WsEventType.postEdited:
        final edited = _wsPostParser.parsePost(postJson);
        if (edited == null) return;
        if (edited.rootId != state.rootPostId &&
            edited.id != state.rootPostId) {
          return;
        }
        final posts = state.posts.map((p) {
          if (p.id == edited.id) return edited;
          return p;
        }).toList();
        emit(state.copyWith(posts: posts));

      case WsEventType.postDeleted:
        try {
          final json = jsonDecode(postJson) as Map<String, dynamic>;
          final postId = json['id'] as String?;
          if (postId == null) return;
          final posts = state.posts.where((p) => p.id != postId).toList();
          emit(state.copyWith(posts: posts));
        } catch (_) {}
    }
  }

  void _handleWsReaction(WsEvent wsEvent, Emitter<ThreadState> emit) {
    final reactionJson = wsEvent.data['reaction'];
    if (reactionJson is! String) return;
    try {
      final reaction = jsonDecode(reactionJson) as Map<String, dynamic>;
      final postId = reaction['post_id'] as String? ?? '';
      final emojiName = reaction['emoji_name'] as String? ?? '';
      final reactUserId = reaction['user_id'] as String? ?? '';
      if (postId.isEmpty || emojiName.isEmpty) return;
      if (!state.posts.any((p) => p.id == postId)) return;

      final isAdd = wsEvent.event == WsEventType.reactionAdded;
      final posts = state.posts.map((p) {
        if (p.id == postId) {
          final reactions = Map<String, List<String>>.from(
            p.reactions.map((k, v) => MapEntry(k, List<String>.from(v))),
          );
          if (isAdd) {
            reactions.putIfAbsent(emojiName, () => []);
            if (!reactions[emojiName]!.contains(reactUserId)) {
              reactions[emojiName]!.add(reactUserId);
            }
          } else {
            reactions[emojiName]?.remove(reactUserId);
            if (reactions[emojiName]?.isEmpty ?? false) {
              reactions.remove(emojiName);
            }
          }
          return p.copyWith(reactions: reactions);
        }
        return p;
      }).toList();
      emit(state.copyWith(posts: posts));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
