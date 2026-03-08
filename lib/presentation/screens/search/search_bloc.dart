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

class SearchFilterChanged extends SearchEvent {
  final String? fromUser;
  final String? inChannel;
  final String? beforeDate;
  final String? afterDate;
  final String? onDate;
  final bool? hasFile;
  final bool? hasImage;
  final bool? hasLink;

  const SearchFilterChanged({
    this.fromUser,
    this.inChannel,
    this.beforeDate,
    this.afterDate,
    this.onDate,
    this.hasFile,
    this.hasImage,
    this.hasLink,
  });

  @override
  List<Object?> get props => [
        fromUser, inChannel, beforeDate, afterDate, onDate,
        hasFile, hasImage, hasLink,
      ];
}

class SearchFilterRemoved extends SearchEvent {
  final String filterKey;
  const SearchFilterRemoved(this.filterKey);
  @override
  List<Object?> get props => [filterKey];
}

class SearchSubmitted extends SearchEvent {
  final String teamId;
  const SearchSubmitted({required this.teamId});
  @override
  List<Object?> get props => [teamId];
}

// State
class SearchState extends Equatable {
  final List<Post> results;
  final bool isLoading;
  final String? error;
  final String query;
  final String? fromUser;
  final String? inChannel;
  final String? beforeDate;
  final String? afterDate;
  final String? onDate;
  final bool hasFile;
  final bool hasImage;
  final bool hasLink;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
    this.fromUser,
    this.inChannel,
    this.beforeDate,
    this.afterDate,
    this.onDate,
    this.hasFile = false,
    this.hasImage = false,
    this.hasLink = false,
  });

  bool get hasActiveFilters =>
      fromUser != null ||
      inChannel != null ||
      beforeDate != null ||
      afterDate != null ||
      onDate != null ||
      hasFile ||
      hasImage ||
      hasLink;

  List<MapEntry<String, String>> get activeFilterChips {
    final chips = <MapEntry<String, String>>[];
    if (fromUser != null) chips.add(MapEntry('from', 'from:$fromUser'));
    if (inChannel != null) chips.add(MapEntry('in', 'in:$inChannel'));
    if (beforeDate != null) chips.add(MapEntry('before', 'before:$beforeDate'));
    if (afterDate != null) chips.add(MapEntry('after', 'after:$afterDate'));
    if (onDate != null) chips.add(MapEntry('on', 'on:$onDate'));
    if (hasFile) chips.add(const MapEntry('hasFile', 'has:file'));
    if (hasImage) chips.add(const MapEntry('hasImage', 'has:image'));
    if (hasLink) chips.add(const MapEntry('hasLink', 'has:link'));
    return chips;
  }

  String get buildSearchTerms {
    final parts = <String>[];
    if (query.isNotEmpty) parts.add(query);
    if (fromUser != null) parts.add('from:$fromUser');
    if (inChannel != null) parts.add('in:$inChannel');
    if (beforeDate != null) parts.add('before:$beforeDate');
    if (afterDate != null) parts.add('after:$afterDate');
    if (onDate != null) parts.add('on:$onDate');
    if (hasFile) parts.add('has:file');
    if (hasImage) parts.add('has:image');
    if (hasLink) parts.add('has:link');
    return parts.join(' ');
  }

  SearchState copyWith({
    List<Post>? results,
    bool? isLoading,
    String? error,
    String? query,
    String? fromUser,
    String? inChannel,
    String? beforeDate,
    String? afterDate,
    String? onDate,
    bool? hasFile,
    bool? hasImage,
    bool? hasLink,
    bool clearFromUser = false,
    bool clearInChannel = false,
    bool clearBeforeDate = false,
    bool clearAfterDate = false,
    bool clearOnDate = false,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
      fromUser: clearFromUser ? null : (fromUser ?? this.fromUser),
      inChannel: clearInChannel ? null : (inChannel ?? this.inChannel),
      beforeDate: clearBeforeDate ? null : (beforeDate ?? this.beforeDate),
      afterDate: clearAfterDate ? null : (afterDate ?? this.afterDate),
      onDate: clearOnDate ? null : (onDate ?? this.onDate),
      hasFile: hasFile ?? this.hasFile,
      hasImage: hasImage ?? this.hasImage,
      hasLink: hasLink ?? this.hasLink,
    );
  }

  @override
  List<Object?> get props => [
        results, isLoading, error, query,
        fromUser, inChannel, beforeDate, afterDate, onDate,
        hasFile, hasImage, hasLink,
      ];
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
    on<SearchFilterChanged>(_onFilterChanged);
    on<SearchFilterRemoved>(_onFilterRemoved);
    on<SearchSubmitted>(_onSubmitted);
  }

  void _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    _debounceTimer?.cancel();

    if (event.query.length < 2 && !state.hasActiveFilters) {
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
      await _performSearch(emit, event.teamId);
      completer.complete();
    });

    await completer.future;
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    _debounceTimer?.cancel();
    emit(const SearchState());
  }

  void _onFilterChanged(
    SearchFilterChanged event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(
      fromUser: event.fromUser,
      inChannel: event.inChannel,
      beforeDate: event.beforeDate,
      afterDate: event.afterDate,
      onDate: event.onDate,
      hasFile: event.hasFile,
      hasImage: event.hasImage,
      hasLink: event.hasLink,
    ));
  }

  void _onFilterRemoved(
    SearchFilterRemoved event,
    Emitter<SearchState> emit,
  ) {
    switch (event.filterKey) {
      case 'from':
        emit(state.copyWith(clearFromUser: true));
      case 'in':
        emit(state.copyWith(clearInChannel: true));
      case 'before':
        emit(state.copyWith(clearBeforeDate: true));
      case 'after':
        emit(state.copyWith(clearAfterDate: true));
      case 'on':
        emit(state.copyWith(clearOnDate: true));
      case 'hasFile':
        emit(state.copyWith(hasFile: false));
      case 'hasImage':
        emit(state.copyWith(hasImage: false));
      case 'hasLink':
        emit(state.copyWith(hasLink: false));
    }
  }

  void _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    final terms = state.buildSearchTerms;
    if (terms.isEmpty) return;
    emit(state.copyWith(isLoading: true));
    await _performSearch(emit, event.teamId);
  }

  Future<void> _performSearch(
    Emitter<SearchState> emit,
    String teamId,
  ) async {
    final terms = state.buildSearchTerms;
    if (terms.isEmpty) {
      emit(state.copyWith(results: const [], isLoading: false));
      return;
    }

    final result = await _postRepository.searchPosts(teamId, terms);

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
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
