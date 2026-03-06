import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/websocket_events.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_category.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/channel_repository.dart';
import '../../../domain/repositories/user_repository.dart';

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

class _ServerSearchResults extends ChannelsEvent {
  final String query;
  final List<Channel> serverChannels;
  final List<User> users;
  const _ServerSearchResults({
    required this.query,
    required this.serverChannels,
    required this.users,
  });
  @override
  List<Object?> get props => [query, serverChannels, users];
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

class ToggleCategoryCollapsed extends ChannelsEvent {
  final String categoryId;
  const ToggleCategoryCollapsed({required this.categoryId});
  @override
  List<Object?> get props => [categoryId];
}

// Grouped section for UI
class ChannelSection extends Equatable {
  final String id;
  final String title;
  final ChannelCategoryType type;
  final List<Channel> channels;
  final bool collapsed;
  final bool isUnreads;

  const ChannelSection({
    required this.id,
    required this.title,
    required this.type,
    required this.channels,
    this.collapsed = false,
    this.isUnreads = false,
  });

  @override
  List<Object?> get props => [id, title, channels, collapsed];
}

// State
class ChannelsState extends Equatable {
  final List<Channel> channels;
  final List<Channel> filteredChannels;
  final List<Channel> serverChannels;
  final List<User> userResults;
  final bool isLoading;
  final bool isSearching;
  final String? error;
  final String searchQuery;
  final List<ChannelSection> sections;
  final List<ChannelCategory> categories;

  const ChannelsState({
    this.channels = const [],
    this.filteredChannels = const [],
    this.serverChannels = const [],
    this.userResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
    this.searchQuery = '',
    this.sections = const [],
    this.categories = const [],
  });

  bool get hasSearchQuery => searchQuery.isNotEmpty;

  ChannelsState copyWith({
    List<Channel>? channels,
    List<Channel>? filteredChannels,
    List<Channel>? serverChannels,
    List<User>? userResults,
    bool? isLoading,
    bool? isSearching,
    String? error,
    String? searchQuery,
    List<ChannelSection>? sections,
    List<ChannelCategory>? categories,
  }) {
    return ChannelsState(
      channels: channels ?? this.channels,
      filteredChannels: filteredChannels ?? this.filteredChannels,
      serverChannels: serverChannels ?? this.serverChannels,
      userResults: userResults ?? this.userResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      sections: sections ?? this.sections,
      categories: categories ?? this.categories,
    );
  }

  @override
  List<Object?> get props => [
        channels,
        filteredChannels,
        serverChannels,
        userResults,
        isLoading,
        isSearching,
        error,
        searchQuery,
        sections,
        categories,
      ];
}

// Sidebar settings (hardcoded for now)
const _kGroupUnreadsSeparately = true;
const _kShowMutedInRecents = false;
const _kDmLimit = 40;
const _kRecentChannelsLimit = 60;

// BLoC
class ChannelsBloc extends Bloc<ChannelsEvent, ChannelsState> {
  final ChannelRepository _channelRepository;
  final UserRepository _userRepository;
  String _userId = '';
  String _teamId = '';
  StreamSubscription<WsEvent>? _wsSub;
  Timer? _searchDebounce;

  ChannelsBloc({
    required ChannelRepository channelRepository,
    required UserRepository userRepository,
  })  : _channelRepository = channelRepository,
        _userRepository = userRepository,
        super(const ChannelsState()) {
    on<LoadChannels>(_onLoadChannels);
    on<RefreshChannels>(_onRefreshChannels);
    on<SearchChannels>(_onSearchChannels);
    on<_ServerSearchResults>(_onServerSearchResults);
    on<MarkChannelAsRead>(_onMarkChannelAsRead);
    on<ToggleMuteChannel>(_onToggleMuteChannel);
    on<ChannelWsEvent>(_onWsEvent);
    on<ToggleCategoryCollapsed>(_onToggleCategoryCollapsed);
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

    final channelsResult = await _channelRepository.getChannelsForUser(
      event.userId,
      event.teamId,
    );

    await channelsResult.fold(
      (failure) async => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (channels) async {
        // Load categories in parallel (non-blocking)
        List<ChannelCategory> categories = [];
        final catResult = await _channelRepository.getChannelCategories(
          event.userId,
          event.teamId,
        );
        catResult.fold((_) {}, (cats) => categories = cats);

        final sorted = _sortChannels(channels);
        final sections = _buildSections(sorted, categories);
        emit(state.copyWith(
          channels: sorted,
          filteredChannels: sorted,
          categories: categories,
          sections: sections,
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
    _searchDebounce?.cancel();
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(state.copyWith(
        filteredChannels: state.channels,
        serverChannels: const [],
        userResults: const [],
        searchQuery: '',
        isSearching: false,
      ));
      return;
    }

    // Immediate local filter
    final filtered = state.channels
        .where((c) =>
            c.displayName.toLowerCase().contains(query) ||
            c.name.toLowerCase().contains(query))
        .toList();

    emit(state.copyWith(
      filteredChannels: filtered,
      searchQuery: query,
      isSearching: true,
    ));

    // Debounced server search
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _performServerSearch(query);
    });
  }

  Future<void> _performServerSearch(String query) async {
    if (_teamId.isEmpty) return;

    final joinedIds = state.channels.map((c) => c.id).toSet();

    final results = await Future.wait([
      _channelRepository.autocompleteChannels(_teamId, query),
      _userRepository.autocompleteUsers(query),
    ]);

    final channelsResult = results[0];
    final usersResult = results[1];

    final serverChannels = channelsResult.fold(
      (_) => <Channel>[],
      (channels) => (channels as List<Channel>)
          .where((c) => !joinedIds.contains(c.id))
          .toList(),
    );

    final users = usersResult.fold(
      (_) => <User>[],
      (users) => (users as List<User>)
          .where((u) => u.id != _userId && !u.isDeleted)
          .toList(),
    );

    add(_ServerSearchResults(
      query: query,
      serverChannels: serverChannels,
      users: users,
    ));
  }

  void _onServerSearchResults(
    _ServerSearchResults event,
    Emitter<ChannelsState> emit,
  ) {
    // Only apply if the query still matches
    if (state.searchQuery != event.query) return;

    emit(state.copyWith(
      serverChannels: event.serverChannels,
      userResults: event.users,
      isSearching: false,
    ));
  }

  Future<void> _onMarkChannelAsRead(
    MarkChannelAsRead event,
    Emitter<ChannelsState> emit,
  ) async {
    // Save old values for rollback
    final oldChannel = state.channels.firstWhere(
      (c) => c.id == event.channelId,
      orElse: () => Channel(id: event.channelId),
    );
    final oldMsgCount = oldChannel.msgCount;
    final oldMsgCountRoot = oldChannel.msgCountRoot;
    final oldMentionCount = oldChannel.mentionCount;
    final oldMentionCountRoot = oldChannel.mentionCountRoot;
    final oldUrgentMentionCount = oldChannel.urgentMentionCount;
    final oldLastViewedAt = oldChannel.lastViewedAt;

    final channels = state.channels.map((c) {
      if (c.id == event.channelId) {
        return c.copyWith(
          msgCount: c.totalMsgCount,
          msgCountRoot: c.totalMsgCountRoot,
          mentionCount: 0,
          mentionCountRoot: 0,
          urgentMentionCount: 0,
          lastViewedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      return c;
    }).toList();

    _emitWithSections(emit, channels);
    _updateAppBadge(channels);

    if (_userId.isNotEmpty) {
      final result =
          await _channelRepository.viewChannel(_userId, event.channelId);
      result.fold(
        (_) {
          // Rollback on error
          final rolledBack = state.channels.map((c) {
            if (c.id == event.channelId) {
              return c.copyWith(
                msgCount: oldMsgCount,
                msgCountRoot: oldMsgCountRoot,
                mentionCount: oldMentionCount,
                mentionCountRoot: oldMentionCountRoot,
                urgentMentionCount: oldUrgentMentionCount,
                lastViewedAt: oldLastViewedAt,
              );
            }
            return c;
          }).toList();
          _emitWithSections(emit, rolledBack);
          _updateAppBadge(rolledBack);
        },
        (_) {}, // Success — keep optimistic state
      );
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

        _emitWithSections(emit, channels);
        _updateAppBadge(channels);
      },
    );
  }

  void _onToggleCategoryCollapsed(
    ToggleCategoryCollapsed event,
    Emitter<ChannelsState> emit,
  ) {
    final updatedCategories = state.categories.map((c) {
      if (c.id == event.categoryId) {
        return c.copyWith(collapsed: !c.collapsed);
      }
      return c;
    }).toList();

    final sections = _buildSections(state.channels, updatedCategories);
    emit(state.copyWith(
      categories: updatedCategories,
      sections: sections,
    ));

    // Update server in background (fire-and-forget)
    if (_userId.isNotEmpty && _teamId.isNotEmpty) {
      final category = updatedCategories.firstWhere(
        (c) => c.id == event.categoryId,
        orElse: () => const ChannelCategory(id: ''),
      );
      if (category.id.isNotEmpty) {
        _channelRepository.updateChannelCategory(
          _userId,
          _teamId,
          event.categoryId,
          <String, dynamic>{'collapsed': category.collapsed},
        );
      }
    }
  }

  Future<void> _updateAppBadge(List<Channel> channels) async {
    int totalMentions = 0;
    for (final c in channels) {
      if (!c.isMuted) {
        totalMentions += c.mentionCountRoot;
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
      case WsEventType.multipleChannelsViewed:
        _handleMultipleChannelsViewed(wsEvent, emit);
      case WsEventType.hello:
        _handleHello();
      case WsEventType.channelMemberUpdated:
        _handleChannelMemberUpdated(wsEvent, emit);
      case WsEventType.sidebarCategoryUpdated:
      case WsEventType.sidebarCategoryCreated:
      case WsEventType.sidebarCategoryDeleted:
        _handleSidebarCategoryEvent(wsEvent, emit);
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

        // Parse post author, create_at, and root_id from JSON
        String? postUserId;
        String rootId = '';
        int createAt = c.lastPostAt;
        if (postJson is String) {
          try {
            final post = jsonDecode(postJson) as Map<String, dynamic>;
            createAt = post['create_at'] as int? ?? c.lastPostAt;
            postUserId = post['user_id'] as String?;
            rootId = post['root_id'] as String? ?? '';
          } catch (_) {}
        }

        // Thread replies don't affect channel-level unread count (CRT mode)
        if (rootId.isNotEmpty) {
          return c.copyWith(lastPostAt: createAt);
        }

        final isOwnPost = postUserId != null && postUserId == _userId;

        // Own posts: increment both totalMsgCount and msgCount so unreadCount stays the same
        if (isOwnPost) {
          return c.copyWith(
            totalMsgCount: c.totalMsgCount + 1,
            totalMsgCountRoot: c.totalMsgCountRoot + 1,
            msgCount: c.msgCount + 1,
            msgCountRoot: c.msgCountRoot + 1,
            lastPostAt: createAt,
          );
        }

        final mentions = wsEvent.data['mentions'] as String?;
        final isMentioned = mentions != null && mentions.contains(_userId);

        return c.copyWith(
          totalMsgCount: c.totalMsgCount + 1,
          totalMsgCountRoot: c.totalMsgCountRoot + 1,
          lastPostAt: createAt,
          mentionCount: c.mentionCount + (isMentioned ? 1 : 0),
          mentionCountRoot: c.mentionCountRoot + (isMentioned ? 1 : 0),
        );
      }
      return c;
    }).toList();

    final sorted = _sortChannels(channels);
    _emitWithSections(emit, sorted);
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
          msgCountRoot: c.totalMsgCountRoot,
          mentionCount: 0,
          mentionCountRoot: 0,
          urgentMentionCount: 0,
        );
      }
      return c;
    }).toList();

    _emitWithSections(emit, channels);
    _updateAppBadge(channels);
  }

  void _handleMultipleChannelsViewed(
      WsEvent wsEvent, Emitter<ChannelsState> emit) {
    // data.channel_times is a JSON-encoded map of channelId -> viewedAt timestamp
    final channelTimesRaw = wsEvent.data['channel_times'];
    if (channelTimesRaw == null) return;

    Map<String, dynamic> channelTimes;
    if (channelTimesRaw is String) {
      try {
        channelTimes = jsonDecode(channelTimesRaw) as Map<String, dynamic>;
      } catch (_) {
        return;
      }
    } else if (channelTimesRaw is Map<String, dynamic>) {
      channelTimes = channelTimesRaw;
    } else {
      return;
    }

    if (channelTimes.isEmpty) return;

    final viewedIds = channelTimes.keys.toSet();
    final channels = state.channels.map((c) {
      if (viewedIds.contains(c.id)) {
        return c.copyWith(
          msgCount: c.totalMsgCount,
          msgCountRoot: c.totalMsgCountRoot,
          mentionCount: 0,
          mentionCountRoot: 0,
          urgentMentionCount: 0,
        );
      }
      return c;
    }).toList();

    _emitWithSections(emit, channels);
    _updateAppBadge(channels);
  }

  /// WS reconnect: reload all channels to resync counters
  void _handleHello() {
    if (_userId.isNotEmpty && _teamId.isNotEmpty) {
      add(const RefreshChannels());
    }
  }

  /// WS channel_member_updated: update mute status from server
  void _handleChannelMemberUpdated(
      WsEvent wsEvent, Emitter<ChannelsState> emit) {
    final memberJson = wsEvent.data['channelMember'];
    if (memberJson == null) return;

    Map<String, dynamic> member;
    if (memberJson is String) {
      try {
        member = jsonDecode(memberJson) as Map<String, dynamic>;
      } catch (_) {
        return;
      }
    } else if (memberJson is Map<String, dynamic>) {
      member = memberJson;
    } else {
      return;
    }

    final channelId = member['channel_id'] as String?;
    final memberUserId = member['user_id'] as String?;
    if (channelId == null || memberUserId != _userId) return;

    bool? isMuted;
    final notifyProps = member['notify_props'] as Map<String, dynamic>?;
    if (notifyProps != null) {
      isMuted = notifyProps['mark_unread'] == 'mention';
    }

    if (isMuted == null) return;

    final channels = state.channels.map((c) {
      if (c.id == channelId) {
        return c.copyWith(isMuted: isMuted);
      }
      return c;
    }).toList();

    _emitWithSections(emit, channels);
    _updateAppBadge(channels);
  }

  /// WS sidebar_category_updated/created/deleted: reload categories from server
  void _handleSidebarCategoryEvent(
      WsEvent wsEvent, Emitter<ChannelsState> emit) {
    if (_userId.isNotEmpty && _teamId.isNotEmpty) {
      // Reload categories from server (fire via event to avoid async in sync handler)
      add(const RefreshChannels());
    }
  }

  // --- Grouping logic ---

  void _emitWithSections(Emitter<ChannelsState> emit, List<Channel> channels) {
    final sections = _buildSections(channels, state.categories);
    emit(state.copyWith(
      channels: channels,
      filteredChannels:
          state.searchQuery.isEmpty ? channels : state.filteredChannels,
      sections: sections,
    ));
  }

  List<ChannelSection> _buildSections(
    List<Channel> allChannels,
    List<ChannelCategory> categories,
  ) {
    if (!_kGroupUnreadsSeparately) {
      // Simple flat list fallback
      return [
        ChannelSection(
          id: '_all',
          title: '',
          type: ChannelCategoryType.channels,
          channels: allChannels,
        ),
      ];
    }

    final channelMap = <String, Channel>{};
    for (final c in allChannels) {
      channelMap[c.id] = c;
    }

    // Step 1: Build unread channels list
    final unreadChannels = <Channel>[];
    for (final c in allChannels) {
      if (c.deleteAt > 0) continue;
      if (c.hasUnread || c.hasMention) {
        unreadChannels.add(c);
      }
    }
    // Sort unreads: muted last, mentions first, then by recency
    unreadChannels.sort((a, b) {
      // Muted last
      if (a.isMuted && !b.isMuted) return 1;
      if (!a.isMuted && b.isMuted) return -1;
      // Mentions first
      if (a.hasMention && !b.hasMention) return -1;
      if (!a.hasMention && b.hasMention) return 1;
      // By recency
      return b.lastPostAt.compareTo(a.lastPostAt);
    });

    final unreadIds = unreadChannels.map((c) => c.id).toSet();

    // Step 2: Build recent channels (excluding unreads and muted)
    final recentCandidates = <Channel>[];
    for (final c in allChannels) {
      if (c.deleteAt > 0) continue;
      if (unreadIds.contains(c.id)) continue;
      if (!_kShowMutedInRecents && c.isMuted) continue;
      recentCandidates.add(c);
    }
    recentCandidates.sort((a, b) => b.lastPostAt.compareTo(a.lastPostAt));
    final recentChannels = recentCandidates.length > _kRecentChannelsLimit
        ? recentCandidates.sublist(0, _kRecentChannelsLimit)
        : recentCandidates;

    final recentIds = recentChannels.map((c) => c.id).toSet();

    // Combined unreads+recent section
    final sections = <ChannelSection>[];

    if (unreadChannels.isNotEmpty || recentChannels.isNotEmpty) {
      sections.add(ChannelSection(
        id: '_unreads_recents',
        title: _kRecentChannelsLimit > 0
            ? 'UNREADS & RECENTS'
            : 'UNREADS',
        type: ChannelCategoryType.channels,
        channels: [...unreadChannels, ...recentChannels],
        isUnreads: true,
      ));
    }

    // Step 3: Build category sections from server categories
    final shownIds = {...unreadIds, ...recentIds};

    if (categories.isNotEmpty) {
      for (final category in categories) {
        final categoryChannels = <Channel>[];
        for (final channelId in category.channelIds) {
          final ch = channelMap[channelId];
          if (ch == null) continue;
          if (shownIds.contains(channelId)) continue;
          if (ch.deleteAt > 0) continue;
          if (!_kShowMutedInRecents && ch.isMuted) continue;
          categoryChannels.add(ch);
        }

        // Filter DM category by limit
        if (category.type == ChannelCategoryType.directMessages) {
          _filterDmChannels(categoryChannels);
        }

        // Sort within category
        _sortCategoryChannels(categoryChannels, category);

        // Skip empty categories (except DMs which might just have no visible channels)
        if (categoryChannels.isEmpty) continue;

        String title;
        switch (category.type) {
          case ChannelCategoryType.favorites:
            title = 'FAVORITES';
          case ChannelCategoryType.channels:
            title = 'CHANNELS';
          case ChannelCategoryType.directMessages:
            title = 'DIRECT MESSAGES';
          case ChannelCategoryType.custom:
            title = category.displayName.toUpperCase();
        }

        // If collapsed, only show unread channels
        final visibleChannels = category.collapsed
            ? categoryChannels.where((c) => c.hasUnread || c.hasMention).toList()
            : categoryChannels;

        sections.add(ChannelSection(
          id: category.id,
          title: title,
          type: category.type,
          channels: visibleChannels,
          collapsed: category.collapsed,
        ));
      }
    } else {
      // Fallback: no categories from server, group by type
      _buildFallbackSections(allChannels, shownIds, sections);
    }

    return sections;
  }

  void _filterDmChannels(List<Channel> dmChannels) {
    if (dmChannels.length <= _kDmLimit) return;

    // Count unreads
    int unreadCount = 0;
    for (final c in dmChannels) {
      if (c.hasUnread || c.hasMention) unreadCount++;
    }

    // Sort: unread first, then by last_viewed_at
    dmChannels.sort((a, b) {
      final aUnread = a.hasUnread || a.hasMention;
      final bUnread = b.hasUnread || b.hasMention;
      if (aUnread && !bUnread) return -1;
      if (!aUnread && bUnread) return 1;
      return b.lastViewedAt.compareTo(a.lastViewedAt);
    });

    // Keep at least max(dmLimit, unreadCount)
    final limit = _kDmLimit > unreadCount ? _kDmLimit : unreadCount;
    if (dmChannels.length > limit) {
      dmChannels.removeRange(limit, dmChannels.length);
    }
  }

  void _sortCategoryChannels(
    List<Channel> channels,
    ChannelCategory category,
  ) {
    switch (category.sorting) {
      case ChannelCategorySorting.recency:
        channels.sort((a, b) => b.lastPostAt.compareTo(a.lastPostAt));
      case ChannelCategorySorting.alphabetical:
      case ChannelCategorySorting.default_:
        channels.sort((a, b) {
          // Muted last
          if (a.isMuted && !b.isMuted) return 1;
          if (!a.isMuted && b.isMuted) return -1;
          final aName = a.displayName.isNotEmpty ? a.displayName : a.name;
          final bName = b.displayName.isNotEmpty ? b.displayName : b.name;
          return aName.toLowerCase().compareTo(bName.toLowerCase());
        });
      case ChannelCategorySorting.manual:
        // Already sorted by channelIds order from server
        break;
    }
  }

  void _buildFallbackSections(
    List<Channel> allChannels,
    Set<String> shownIds,
    List<ChannelSection> sections,
  ) {
    final regularChannels = <Channel>[];
    final dmChannels = <Channel>[];

    for (final c in allChannels) {
      if (shownIds.contains(c.id)) continue;
      if (c.deleteAt > 0) continue;
      if (!_kShowMutedInRecents && c.isMuted) continue;

      if (c.isDirect || c.isGroup) {
        dmChannels.add(c);
      } else {
        regularChannels.add(c);
      }
    }

    regularChannels.sort((a, b) {
      final aName = a.displayName.isNotEmpty ? a.displayName : a.name;
      final bName = b.displayName.isNotEmpty ? b.displayName : b.name;
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    _filterDmChannels(dmChannels);
    dmChannels.sort((a, b) => b.lastPostAt.compareTo(a.lastPostAt));

    if (regularChannels.isNotEmpty) {
      sections.add(ChannelSection(
        id: '_channels',
        title: 'CHANNELS',
        type: ChannelCategoryType.channels,
        channels: regularChannels,
      ));
    }

    if (dmChannels.isNotEmpty) {
      sections.add(ChannelSection(
        id: '_dms',
        title: 'DIRECT MESSAGES',
        type: ChannelCategoryType.directMessages,
        channels: dmChannels,
      ));
    }
  }

  List<Channel> _sortChannels(List<Channel> channels) {
    final sorted = List<Channel>.from(channels);
    sorted.sort((a, b) => b.lastPostAt.compareTo(a.lastPostAt));
    return sorted;
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    _searchDebounce?.cancel();
    return super.close();
  }
}
