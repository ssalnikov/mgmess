import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/file_info.dart';
import '../../../domain/repositories/file_repository.dart';

// State

enum ChannelFilesFilter { all, images, documents }

class ChannelFilesState extends Equatable {
  final List<({FileInfo file, int createAt})> files;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final ChannelFilesFilter filter;

  const ChannelFilesState({
    this.files = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.filter = ChannelFilesFilter.all,
  });

  List<({FileInfo file, int createAt})> get filteredFiles {
    switch (filter) {
      case ChannelFilesFilter.images:
        return files.where((f) => f.file.isImage).toList();
      case ChannelFilesFilter.documents:
        return files.where((f) => !f.file.isImage && !f.file.isVideo).toList();
      case ChannelFilesFilter.all:
        return files;
    }
  }

  ChannelFilesState copyWith({
    List<({FileInfo file, int createAt})>? files,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    ChannelFilesFilter? filter,
  }) {
    return ChannelFilesState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [files, isLoading, isLoadingMore, hasMore, error, filter];
}

// Cubit

class ChannelFilesCubit extends Cubit<ChannelFilesState> {
  final FileRepository _fileRepository;
  final String channelId;
  static const _perPage = 20;

  ChannelFilesCubit({
    required FileRepository fileRepository,
    required this.channelId,
  })  : _fileRepository = fileRepository,
        super(const ChannelFilesState());

  Future<void> loadFiles() async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _fileRepository.getChannelFiles(
      channelId,
      page: 0,
      perPage: _perPage,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (files) => emit(state.copyWith(
        isLoading: false,
        files: files,
        hasMore: files.length >= _perPage,
      )),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));
    final nextPage = state.files.length ~/ _perPage;

    final result = await _fileRepository.getChannelFiles(
      channelId,
      page: nextPage,
      perPage: _perPage,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        error: failure.message,
      )),
      (files) => emit(state.copyWith(
        isLoadingMore: false,
        files: [...state.files, ...files],
        hasMore: files.length >= _perPage,
      )),
    );
  }

  void setFilter(ChannelFilesFilter filter) {
    emit(state.copyWith(filter: filter));
  }
}
