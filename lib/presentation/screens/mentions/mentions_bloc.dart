import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/post.dart';
import '../../../domain/repositories/post_repository.dart';

// Events
abstract class MentionsEvent extends Equatable {
  const MentionsEvent();
  @override
  List<Object?> get props => [];
}

class LoadMentions extends MentionsEvent {
  final String teamId;
  final String username;
  const LoadMentions({required this.teamId, required this.username});
  @override
  List<Object?> get props => [teamId, username];
}

// State
class MentionsState extends Equatable {
  final List<Post> posts;
  final bool isLoading;
  final String? error;

  const MentionsState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });

  MentionsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? error,
  }) {
    return MentionsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [posts, isLoading, error];
}

// BLoC
class MentionsBloc extends Bloc<MentionsEvent, MentionsState> {
  final PostRepository _postRepository;

  MentionsBloc({required PostRepository postRepository})
      : _postRepository = postRepository,
        super(const MentionsState()) {
    on<LoadMentions>(_onLoad);
  }

  Future<void> _onLoad(
    LoadMentions event,
    Emitter<MentionsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _postRepository.searchPosts(
      event.teamId,
      '@${event.username}',
    );

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
}
