import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/websocket_events.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/repositories/channel_repository.dart';

// Events
abstract class ChannelsEvent extends Equatable {
  const ChannelsEvent();
  @override
  List<Object?> get props => [];
}

class LoadChannels extends ChannelsEvent {
  final String userId;
  final String teamId;
  const LoadChannels({required this.userId, required this.teamId});
  @override
  List<Object?> get props => [userId, teamId];
}

class RefreshChannels extends ChannelsEvent {
  const RefreshChannels();
}

class SearchChannels extends ChannelsEvent {
  final String query;
  const SearchChannels({required this.query});
  @override
  List<Object?> get props => [query];
}

class MarkChannelAsRead extends ChannelsEvent {
  final String channelId;
  const MarkChannelAsRead({required this.channelId});
  @override
  List<Object?> get props => [channelId];
}

class ToggleMuteChannel extends ChannelsEvent {
  final String channelId;
  final String userId;
  const ToggleMuteChannel({required this.channelId, required this.userId});
  @override
  List<Object?> get props => [channelId, userId];
}

class ChannelWsEvent extends ChannelsEvent {
  final WsEvent wsEvent;
  const ChannelWsEvent({required this.wsEvent});
  @override
  List<Object?> get props => [wsEvent];
}

// State
class ChannelsState extends Equatable {
  final List<Channel> channels;
  final List<Channel> filteredChannels;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const ChannelsState({
    this.channels = const [],
    this.filteredChannels = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  ChannelsState copyWith({
    List<Channel>? channels,
    List<Channel>? filteredChannels,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return ChannelsState(
      channels: channels ?? this.channels,
      filteredChannels: filteredChannels ?? this.filteredChannels,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props =>
      [channels, filteredChannels, isLoading, error, searchQuery];
}

// BLoC
class ChannelsBloc extends Bloc<ChannelsEvent, ChannelsState> {
  final ChannelRepository _channelRepository;
  String _userId = '';
  String _teamId = '';
  StreamSubscription<WsEvent>? _wsSub;

  ChannelsBloc({
    required ChannelRepository channelRepository,
  })  : _channelRepository = channelRepository,
        super(const ChannelsState()) {
    on<LoadChannels>(_onLoadChannels);
    on<RefreshChannels>(_onRefreshChannels);
    on<SearchChannels>(_onSearchChannels);
    on<MarkChannelAsRead>(_onMarkChannelAsRead);
    on<ToggleMuteChannel>(_onToggleMuteChannel);
    on<ChannelWsEvent>(_onWsEvent);
  }

  void subscribeToWs(Stream<WsEvent> wsEvents) {
    _wsSub?.cancel();
    _wsSub = wsEvents.listen((event) {
      add(ChannelWsEvent(wsEvent: event));
    });
  }

  Future<void> _onLoadChannels(
    LoadChannels event,
    Emitter<ChannelsState> emit,
  ) async {
    _userId = event.userId;
    _teamId = event.teamId;
    emit(state.copyWith(isLoading: true));

    final result = await _channelRepository.getChannelsForUser(
      event.userId,
      event.teamId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (channels) {
        final sorted = _sortChannels(channels);
        emit(state.copyWith(
          channels: sorted,
          filteredChannels: sorted,
          isLoading: false,
        ));
        _updateAppBadge(sorted);
      },
    );
  }

  Future<void> _onRefreshChannels(
    RefreshChannels event,
    Emitter<ChannelsState> emit,
  ) async {
    if (_userId.isEmpty || _teamId.isEmpty) return;
    add(LoadChannels(userId: _userId, teamId: _teamId));
  }

  void _onSearchChannels(
    SearchChannels event,
    Emitter<ChannelsState> emit,
  ) {
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(state.copyWith(
        filteredChannels: state.channels,
        searchQuery: '',
      ));
      return;
    }
    final filtered = state.channels
        .where((c) =>
            c.displayName.toLowerCase().contains(query) ||
            c.name.toLowerCase().contains(query))
        .toList();
    emit(state.copyWith(
      filteredChannels: filtered,
      searchQuery: query,
    ));
  }

  Future<void> _onMarkChannelAsRead(
    MarkChannelAsRead event,
    Emitter<ChannelsState> emit,
  ) async {
    final channels = state.channels.map((c) {
      if (c.id == event.channelId) {
        return c.copyWith(
          msgCount: c.totalMsgCount,
          mentionCount: 0,
          lastViewedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return c;
    }).toList();

    emit(state.copyWith(
      channels: channels,
      filteredChannels:
          state.searchQuery.isEmpty ? channels : state.filteredChannels,
    ));
    _updateAppBadge(channels);

    if (_userId.isNotEmpty) {
      await _channelRepository.viewChannel(_userId, event.channelId);
    }
  }

  Future<void> _onToggleMuteChannel(
    ToggleMuteChannel event,
    Emitter<ChannelsState> emit,
  ) async {
    final channel = state.channels.firstWhere(
      (c) => c.id == event.channelId,
      orElse: () => Channel(id: event.channelId),
    );

    final shouldMute = !channel.isMuted;

    final result = shouldMute
        ? await _channelRepository.muteChannel(event.channelId, event.userId)
        : await _channelRepository.unmuteChannel(
            event.channelId, event.userId);

    result.fold(
      (_) {},
      (_) {
        final channels = state.channels.map((c) {
          if (c.id == event.channelId) {
            return c.copyWith(isMuted: shouldMute);
          }
          return c;
        }).toList();

        emit(state.copyWith(
          channels: channels,
          filteredChannels:
              state.searchQuery.isEmpty ? channels : state.filteredChannels,
        ));
        _updateAppBadge(channels);
      },
    );
  }

  Future<void> _updateAppBadge(List<Channel> channels) async {
    int totalMentions = 0;
    for (final c in channels) {
      if (!c.isMuted) {
        totalMentions += c.mentionCount;
      }
    }
    try {
      if (totalMentions > 0) {
        await AppBadgePlus.updateBadge(totalMentions);
      } else {
        await AppBadgePlus.updateBadge(0);
      }
    } catch (_) {
      // Platform channel not available (e.g. in tests)
    }
  }

  void _onWsEvent(ChannelWsEvent event, Emitter<ChannelsState> emit) {
    final wsEvent = event.wsEvent;
    switch (wsEvent.event) {
      case WsEventType.posted:
        _handleNewPost(wsEvent, emit);
      case WsEventType.channelViewed:
        _handleChannelViewed(wsEvent, emit);
      default:
        break;
    }
  }

  void _handleNewPost(WsEvent wsEvent, Emitter<ChannelsState> emit) {
    final channelId = wsEvent.channelId;
    if (channelId == null) return;

    final channels = state.channels.map((c) {
      if (c.id == channelId) {
        final postJson = wsEvent.data['post'];

        // Parse post author and create_at from JSON
        String? postUserId;
        int createAt = c.lastPostAt;
        if (postJson is String) {
          try {
            final post = jsonDecode(postJson) as Map<String, dynamic>;
            createAt = post['create_at'] as int? ?? c.lastPostAt;
            postUserId = post['user_id'] as String?;
          } catch (_) {}
        }

        final isOwnPost = postUserId != null && postUserId == _userId;

        // Own posts: increment both totalMsgCount and msgCount so unreadCount stays the same
        if (isOwnPost) {
          return c.copyWith(
            totalMsgCount: c.totalMsgCount + 1,
            msgCount: c.msgCount + 1,
            lastPostAt: createAt,
          );
        }

        final mentions = wsEvent.data['mentions'] as String?;
        final mentionIncrement =
            mentions != null && mentions.contains(_userId) ? 1 : 0;

        return c.copyWith(
          totalMsgCount: c.totalMsgCount + 1,
          lastPostAt: createAt,
          mentionCount: c.mentionCount + mentionIncrement,
        );
      }
      return c;
    }).toList();

    final sorted = _sortChannels(channels);
    emit(state.copyWith(
      channels: sorted,
      filteredChannels:
          state.searchQuery.isEmpty ? sorted : state.filteredChannels,
    ));
    _updateAppBadge(sorted);
  }

  void _handleChannelViewed(
      WsEvent wsEvent, Emitter<ChannelsState> emit) {
    final channelId = wsEvent.data['channel_id'] as String?;
    if (channelId == null) return;

    final channels = state.channels.map((c) {
      if (c.id == channelId) {
        return c.copyWith(
          msgCount: c.totalMsgCount,
          mentionCount: 0,
        );
      }
      return c;
    }).toList();

    emit(state.copyWith(
      channels: channels,
      filteredChannels:
          state.searchQuery.isEmpty ? channels : state.filteredChannels,
    ));
    _updateAppBadge(channels);
  }

  List<Channel> _sortChannels(List<Channel> channels) {
    final sorted = List<Channel>.from(channels);
    sorted.sort((a, b) => b.lastPostAt.compareTo(a.lastPostAt));
    return sorted;
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
