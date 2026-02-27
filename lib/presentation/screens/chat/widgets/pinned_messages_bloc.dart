import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/post.dart';
import '../../../../domain/repositories/post_repository.dart';

// Events
abstract class PinnedMessagesEvent extends Equatable {
  const PinnedMessagesEvent();
  @override
  List<Object?> get props => [];
}

class LoadPinnedMessages extends PinnedMessagesEvent {
  final String channelId;
  const LoadPinnedMessages({required this.channelId});
  @override
  List<Object?> get props => [channelId];
}

class UnpinMessage extends PinnedMessagesEvent {
  final String postId;
  const UnpinMessage({required this.postId});
  @override
  List<Object?> get props => [postId];
}

// State
class PinnedMessagesState extends Equatable {
  final List<Post> posts;
  final bool isLoading;
  final String? error;

  const PinnedMessagesState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });

  PinnedMessagesState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? error,
  }) {
    return PinnedMessagesState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  Map<String, List<Post>> get groupedByDate {
    final map = <String, List<Post>>{};
    for (final post in posts) {
      final date = DateTime.fromMillisecondsSinceEpoch(post.createAt);
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(post);
    }
    return map;
  }

  @override
  List<Object?> get props => [posts, isLoading, error];
}

// BLoC
class PinnedMessagesBloc
    extends Bloc<PinnedMessagesEvent, PinnedMessagesState> {
  final PostRepository _postRepository;

  PinnedMessagesBloc({required PostRepository postRepository})
      : _postRepository = postRepository,
        super(const PinnedMessagesState()) {
    on<LoadPinnedMessages>(_onLoad);
    on<UnpinMessage>(_onUnpin);
  }

  Future<void> _onLoad(
    LoadPinnedMessages event,
    Emitter<PinnedMessagesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result =
        await _postRepository.getPinnedPosts(event.channelId);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (posts) => emit(state.copyWith(
        posts: posts,
        isLoading: false,
      )),
    );
  }

  Future<void> _onUnpin(
    UnpinMessage event,
    Emitter<PinnedMessagesState> emit,
  ) async {
    final result = await _postRepository.unpinPost(event.postId);
    result.fold(
      (_) {},
      (_) {
        final posts =
            state.posts.where((p) => p.id != event.postId).toList();
        emit(state.copyWith(posts: posts));
      },
    );
  }
}
