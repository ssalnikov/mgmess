import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/post.dart';
import '../../../domain/repositories/post_repository.dart';

// Events
abstract class SavedMessagesEvent extends Equatable {
  const SavedMessagesEvent();
  @override
  List<Object?> get props => [];
}

class LoadSavedMessages extends SavedMessagesEvent {
  final String userId;
  const LoadSavedMessages({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class UnflagMessage extends SavedMessagesEvent {
  final String userId;
  final String postId;
  const UnflagMessage({required this.userId, required this.postId});
  @override
  List<Object?> get props => [userId, postId];
}

// State
class SavedMessagesState extends Equatable {
  final List<Post> posts;
  final bool isLoading;
  final String? error;

  const SavedMessagesState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });

  SavedMessagesState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? error,
  }) {
    return SavedMessagesState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [posts, isLoading, error];
}

// BLoC
class SavedMessagesBloc
    extends Bloc<SavedMessagesEvent, SavedMessagesState> {
  final PostRepository _postRepository;

  SavedMessagesBloc({required PostRepository postRepository})
      : _postRepository = postRepository,
        super(const SavedMessagesState()) {
    on<LoadSavedMessages>(_onLoad);
    on<UnflagMessage>(_onUnflag);
  }

  Future<void> _onLoad(
    LoadSavedMessages event,
    Emitter<SavedMessagesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result =
        await _postRepository.getFlaggedPosts(event.userId);

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

  Future<void> _onUnflag(
    UnflagMessage event,
    Emitter<SavedMessagesState> emit,
  ) async {
    final result = await _postRepository.unflagPost(
      event.userId,
      event.postId,
    );
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
