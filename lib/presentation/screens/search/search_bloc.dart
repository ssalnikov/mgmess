import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/post.dart';
import '../../../domain/repositories/post_repository.dart';

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  final String teamId;
  const SearchQueryChanged({required this.query, required this.teamId});
  @override
  List<Object?> get props => [query, teamId];
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}

// State
class SearchState extends Equatable {
  final List<Post> results;
  final bool isLoading;
  final String? error;
  final String query;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  SearchState copyWith({
    List<Post>? results,
    bool? isLoading,
    String? error,
    String? query,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [results, isLoading, error, query];
}

// BLoC
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final PostRepository _postRepository;
  Timer? _debounceTimer;

  SearchBloc({required PostRepository postRepository})
      : _postRepository = postRepository,
        super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchCleared>(_onCleared);
  }

  void _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    _debounceTimer?.cancel();

    if (event.query.length < 2) {
      emit(state.copyWith(
        results: const [],
        isLoading: false,
        query: event.query,
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, query: event.query));

    final completer = Completer<void>();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final result = await _postRepository.searchPosts(
        event.teamId,
        event.query,
      );

      result.fold(
        (failure) => emit(state.copyWith(
          isLoading: false,
          error: failure.message,
        )),
        (posts) => emit(state.copyWith(
          results: posts,
          isLoading: false,
        )),
      );
      completer.complete();
    });

    await completer.future;
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    _debounceTimer?.cancel();
    emit(const SearchState());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
