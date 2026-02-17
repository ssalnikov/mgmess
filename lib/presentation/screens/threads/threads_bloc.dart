import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_thread.dart';
import '../../../domain/repositories/post_repository.dart';

// Events
abstract class ThreadsEvent extends Equatable {
  const ThreadsEvent();
  @override
  List<Object?> get props => [];
}

class LoadThreads extends ThreadsEvent {
  final String userId;
  final String teamId;
  const LoadThreads({required this.userId, required this.teamId});
  @override
  List<Object?> get props => [userId, teamId];
}

class LoadMoreThreads extends ThreadsEvent {
  const LoadMoreThreads();
}

// State
class ThreadsState extends Equatable {
  final List<UserThread> threads;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? userId;
  final String? teamId;

  const ThreadsState({
    this.threads = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.userId,
    this.teamId,
  });

  ThreadsState copyWith({
    List<UserThread>? threads,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? userId,
    String? teamId,
  }) {
    return ThreadsState(
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
    );
  }

  @override
  List<Object?> get props =>
      [threads, isLoading, isLoadingMore, hasMore, error, userId, teamId];
}

// BLoC
class ThreadsBloc extends Bloc<ThreadsEvent, ThreadsState> {
  final PostRepository _postRepository;
  static const _perPage = 25;

  ThreadsBloc({required PostRepository postRepository})
      : _postRepository = postRepository,
        super(const ThreadsState()) {
    on<LoadThreads>(_onLoad);
    on<LoadMoreThreads>(_onLoadMore);
  }

  Future<void> _onLoad(
    LoadThreads event,
    Emitter<ThreadsState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      userId: event.userId,
      teamId: event.teamId,
    ));

    final result = await _postRepository.getUserThreads(
      event.userId,
      event.teamId,
      perPage: _perPage,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (threads) => emit(state.copyWith(
        threads: threads,
        isLoading: false,
        hasMore: threads.length >= _perPage,
      )),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreThreads event,
    Emitter<ThreadsState> emit,
  ) async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.userId == null ||
        state.teamId == null) return;

    emit(state.copyWith(isLoadingMore: true));

    final lastThread = state.threads.last;
    final result = await _postRepository.getUserThreads(
      state.userId!,
      state.teamId!,
      perPage: _perPage,
      before: lastThread.lastReplyAt.toString(),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        error: failure.message,
      )),
      (threads) => emit(state.copyWith(
        threads: [...state.threads, ...threads],
        isLoadingMore: false,
        hasMore: threads.length >= _perPage,
      )),
    );
  }
}
