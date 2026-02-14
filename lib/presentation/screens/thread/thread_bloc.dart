import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/websocket_events.dart';
import '../../../data/models/post_model.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/repositories/post_repository.dart';

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

  const ThreadState({
    this.rootPostId = '',
    this.channelId = '',
    this.posts = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  ThreadState copyWith({
    String? rootPostId,
    String? channelId,
    List<Post>? posts,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ThreadState(
      rootPostId: rootPostId ?? this.rootPostId,
      channelId: channelId ?? this.channelId,
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [rootPostId, channelId, posts, isLoading, isSending, error];
}

// BLoC
class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  final PostRepository _postRepository;
  StreamSubscription<WsEvent>? _wsSub;

  ThreadBloc({required PostRepository postRepository})
      : _postRepository = postRepository,
        super(const ThreadState()) {
    on<LoadThread>(_onLoadThread);
    on<SendThreadReply>(_onSendReply);
    on<ThreadWsEvent>(_onWsEvent);
  }

  void subscribeToWs(Stream<WsEvent> wsEvents) {
    _wsSub?.cancel();
    _wsSub = wsEvents
        .where((e) =>
            e.event == WsEventType.posted ||
            e.event == WsEventType.postEdited ||
            e.event == WsEventType.postDeleted)
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

  void _onWsEvent(ThreadWsEvent event, Emitter<ThreadState> emit) {
    final wsEvent = event.wsEvent;
    final postJson = wsEvent.data['post'];
    if (postJson is! String) return;

    try {
      final json = jsonDecode(postJson) as Map<String, dynamic>;

      switch (wsEvent.event) {
        case WsEventType.posted:
          final post = PostModel.fromJson(json);
          if (post.rootId != state.rootPostId &&
              post.id != state.rootPostId) {
            return;
          }
          if (state.posts.any((p) => p.id == post.id)) return;
          emit(state.copyWith(posts: [...state.posts, post]));

        case WsEventType.postEdited:
          final edited = PostModel.fromJson(json);
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
          final postId = json['id'] as String?;
          if (postId == null) return;
          final posts = state.posts.where((p) => p.id != postId).toList();
          emit(state.copyWith(posts: posts));
      }
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
