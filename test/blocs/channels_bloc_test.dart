import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/failures.dart';
import 'package:mgmess/core/network/websocket_events.dart';
import 'package:mgmess/domain/entities/channel.dart';
import 'package:mgmess/domain/repositories/channel_repository.dart';
import 'package:mgmess/domain/repositories/user_repository.dart';
import 'package:mgmess/presentation/screens/channels/channels_bloc.dart';

class MockChannelRepository extends Mock implements ChannelRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockChannelRepository mockRepo;
  late MockUserRepository mockUserRepo;

  setUp(() {
    mockRepo = MockChannelRepository();
    mockUserRepo = MockUserRepository();
  });

  const channels = [
    Channel(
      id: 'ch1',
      name: 'general',
      displayName: 'General',
      type: ChannelType.open,
      lastPostAt: 3000,
      totalMsgCount: 10,
      msgCount: 5,
    ),
    Channel(
      id: 'ch2',
      name: 'dev',
      displayName: 'Development',
      type: ChannelType.private_,
      lastPostAt: 2000,
      totalMsgCount: 20,
      msgCount: 20,
    ),
  ];

  group('ChannelsBloc', () {
    blocTest<ChannelsBloc, ChannelsState>(
      'emits [loading, loaded] when LoadChannels succeeds',
      build: () {
        when(() => mockRepo.getChannelsForUser(any(), any()))
            .thenAnswer((_) async => const Right(channels));
        return ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo);
      },
      act: (bloc) => bloc.add(const LoadChannels(
        userId: 'user1',
        teamId: 'team1',
      )),
      expect: () => [
        const ChannelsState(isLoading: true),
        isA<ChannelsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.channels.length, 'channels.length', 2)
            .having(
              (s) => s.channels.first.id,
              'first channel (sorted by lastPostAt)',
              'ch1',
            ),
      ],
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'emits [loading, error] when LoadChannels fails',
      build: () {
        when(() => mockRepo.getChannelsForUser(any(), any()))
            .thenAnswer((_) async =>
                const Left(ServerFailure(message: 'Network error')));
        return ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo);
      },
      act: (bloc) => bloc.add(const LoadChannels(
        userId: 'user1',
        teamId: 'team1',
      )),
      expect: () => [
        const ChannelsState(isLoading: true),
        isA<ChannelsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.error, 'error', 'Network error'),
      ],
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'SearchChannels filters channels by name',
      build: () => ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo),
      seed: () => ChannelsState(
        channels: channels,
        filteredChannels: channels,
      ),
      act: (bloc) => bloc.add(const SearchChannels(query: 'dev')),
      expect: () => [
        isA<ChannelsState>()
            .having(
              (s) => s.filteredChannels.length,
              'filteredChannels.length',
              1,
            )
            .having(
              (s) => s.filteredChannels.first.id,
              'filtered channel id',
              'ch2',
            )
            .having((s) => s.searchQuery, 'searchQuery', 'dev'),
      ],
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'SearchChannels with empty query returns all channels',
      build: () => ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo),
      seed: () => ChannelsState(
        channels: channels,
        filteredChannels: [channels[1]],
        searchQuery: 'dev',
      ),
      act: (bloc) => bloc.add(const SearchChannels(query: '')),
      expect: () => [
        isA<ChannelsState>()
            .having(
              (s) => s.filteredChannels.length,
              'filteredChannels.length',
              2,
            )
            .having((s) => s.searchQuery, 'searchQuery', ''),
      ],
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'WS posted from own user does not increase unread count',
      build: () {
        when(() => mockRepo.getChannelsForUser(any(), any()))
            .thenAnswer((_) async => const Right([
                  Channel(
                    id: 'ch1',
                    name: 'general',
                    displayName: 'General',
                    type: ChannelType.open,
                    lastPostAt: 3000,
                    totalMsgCount: 10,
                    msgCount: 10,
                  ),
                ]));
        return ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo);
      },
      act: (bloc) async {
        // Set _userId via LoadChannels
        bloc.add(const LoadChannels(userId: 'user1', teamId: 'team1'));
        await Future.delayed(const Duration(milliseconds: 50));
        // Send WS event from own user
        final post = jsonEncode({
          'id': 'p1',
          'channel_id': 'ch1',
          'user_id': 'user1',
          'create_at': 5000,
        });
        bloc.add(ChannelWsEvent(wsEvent: WsEvent(
          event: WsEventType.posted,
          data: {'post': post},
          broadcast: {'channel_id': 'ch1'},
        )));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        // LoadChannels loading
        isA<ChannelsState>().having((s) => s.isLoading, 'isLoading', true),
        // LoadChannels loaded
        isA<ChannelsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.channels.first.unreadCount, 'unread', 0),
        // After own WS post: unread still 0 (both totalMsgCount and msgCount incremented)
        isA<ChannelsState>()
            .having((s) => s.channels.first.totalMsgCount, 'totalMsgCount', 11)
            .having((s) => s.channels.first.msgCount, 'msgCount', 11)
            .having((s) => s.channels.first.unreadCount, 'unread', 0),
      ],
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'WS posted from other user increases unread count',
      build: () => ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo),
      seed: () => const ChannelsState(
        channels: [
          Channel(
            id: 'ch1',
            name: 'general',
            displayName: 'General',
            type: ChannelType.open,
            lastPostAt: 3000,
            totalMsgCount: 10,
            msgCount: 10,
          ),
        ],
        filteredChannels: [
          Channel(
            id: 'ch1',
            name: 'general',
            displayName: 'General',
            type: ChannelType.open,
            lastPostAt: 3000,
            totalMsgCount: 10,
            msgCount: 10,
          ),
        ],
      ),
      act: (bloc) {
        final post = jsonEncode({
          'id': 'p1',
          'channel_id': 'ch1',
          'user_id': 'other_user',
          'create_at': 5000,
        });
        bloc.add(ChannelWsEvent(wsEvent: WsEvent(
          event: WsEventType.posted,
          data: {'post': post},
          broadcast: {'channel_id': 'ch1'},
        )));
      },
      expect: () => [
        isA<ChannelsState>()
            .having(
              (s) => s.channels.first.totalMsgCount,
              'totalMsgCount increased',
              11,
            )
            .having(
              (s) => s.channels.first.msgCount,
              'msgCount unchanged',
              10,
            )
            .having(
              (s) => s.channels.first.unreadCount,
              'unreadCount is 1',
              1,
            ),
      ],
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'WS thread reply does not increase channel unread count',
      build: () => ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo),
      seed: () => const ChannelsState(
        channels: [
          Channel(
            id: 'ch1',
            name: 'general',
            displayName: 'General',
            type: ChannelType.open,
            lastPostAt: 3000,
            totalMsgCount: 10,
            msgCount: 10,
          ),
        ],
        filteredChannels: [
          Channel(
            id: 'ch1',
            name: 'general',
            displayName: 'General',
            type: ChannelType.open,
            lastPostAt: 3000,
            totalMsgCount: 10,
            msgCount: 10,
          ),
        ],
      ),
      act: (bloc) {
        final post = jsonEncode({
          'id': 'reply1',
          'channel_id': 'ch1',
          'user_id': 'other_user',
          'root_id': 'parent_post',
          'create_at': 5000,
        });
        bloc.add(ChannelWsEvent(wsEvent: WsEvent(
          event: WsEventType.posted,
          data: {'post': post},
          broadcast: {'channel_id': 'ch1'},
        )));
      },
      expect: () => [
        isA<ChannelsState>()
            .having(
              (s) => s.channels.first.totalMsgCount,
              'totalMsgCount unchanged',
              10,
            )
            .having(
              (s) => s.channels.first.msgCount,
              'msgCount unchanged',
              10,
            )
            .having(
              (s) => s.channels.first.unreadCount,
              'unreadCount still 0',
              0,
            )
            .having(
              (s) => s.channels.first.lastPostAt,
              'lastPostAt updated',
              5000,
            ),
      ],
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'MarkChannelAsRead updates lastViewedAt to current time',
      build: () {
        when(() => mockRepo.viewChannel(any(), any()))
            .thenAnswer((_) async => const Right(null));
        return ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo);
      },
      seed: () => const ChannelsState(
        channels: channels,
        filteredChannels: channels,
      ),
      act: (bloc) {
        bloc.add(const MarkChannelAsRead(channelId: 'ch1'));
      },
      expect: () => [
        isA<ChannelsState>().having(
          (s) => s.channels
              .firstWhere((c) => c.id == 'ch1')
              .lastViewedAt,
          'lastViewedAt is recent',
          isA<int>().having(
            (v) => v > 0,
            'greater than 0',
            true,
          ),
        ),
      ],
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'MarkChannelAsRead rolls back on viewChannel API error',
      build: () {
        when(() => mockRepo.viewChannel(any(), any()))
            .thenAnswer((_) async =>
                const Left(ServerFailure(message: 'Server error')));
        when(() => mockRepo.getChannelsForUser(any(), any()))
            .thenAnswer((_) async => const Right(channels));
        return ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo);
      },
      act: (bloc) async {
        // Set _userId via LoadChannels
        bloc.add(const LoadChannels(userId: 'user1', teamId: 'team1'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const MarkChannelAsRead(channelId: 'ch1'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        // LoadChannels loading
        isA<ChannelsState>().having((s) => s.isLoading, 'isLoading', true),
        // LoadChannels loaded
        isA<ChannelsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having(
              (s) => s.channels.firstWhere((c) => c.id == 'ch1').unreadCount,
              'unread before mark',
              5,
            ),
        // Optimistic update
        isA<ChannelsState>().having(
          (s) => s.channels.firstWhere((c) => c.id == 'ch1').unreadCount,
          'unread after optimistic',
          0,
        ),
        // Rollback after API error
        isA<ChannelsState>().having(
          (s) => s.channels.firstWhere((c) => c.id == 'ch1').unreadCount,
          'unread after rollback',
          5,
        ),
      ],
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'WS multiple_channels_viewed marks multiple channels as read',
      build: () => ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo),
      seed: () => const ChannelsState(
        channels: [
          Channel(
            id: 'ch1',
            name: 'general',
            displayName: 'General',
            totalMsgCount: 15,
            msgCount: 10,
            mentionCount: 2,
            lastPostAt: 3000,
          ),
          Channel(
            id: 'ch2',
            name: 'dev',
            displayName: 'Development',
            totalMsgCount: 20,
            msgCount: 18,
            mentionCount: 1,
            lastPostAt: 2000,
          ),
        ],
        filteredChannels: [
          Channel(
            id: 'ch1',
            name: 'general',
            displayName: 'General',
            totalMsgCount: 15,
            msgCount: 10,
            mentionCount: 2,
            lastPostAt: 3000,
          ),
          Channel(
            id: 'ch2',
            name: 'dev',
            displayName: 'Development',
            totalMsgCount: 20,
            msgCount: 18,
            mentionCount: 1,
            lastPostAt: 2000,
          ),
        ],
      ),
      act: (bloc) {
        bloc.add(ChannelWsEvent(wsEvent: WsEvent(
          event: WsEventType.multipleChannelsViewed,
          data: {
            'channel_times': jsonEncode({
              'ch1': 4000,
              'ch2': 3000,
            }),
          },
        )));
      },
      expect: () => [
        isA<ChannelsState>()
            .having(
              (s) => s.channels.firstWhere((c) => c.id == 'ch1').unreadCount,
              'ch1 unread',
              0,
            )
            .having(
              (s) => s.channels.firstWhere((c) => c.id == 'ch1').mentionCount,
              'ch1 mentions',
              0,
            )
            .having(
              (s) => s.channels.firstWhere((c) => c.id == 'ch2').unreadCount,
              'ch2 unread',
              0,
            )
            .having(
              (s) => s.channels.firstWhere((c) => c.id == 'ch2').mentionCount,
              'ch2 mentions',
              0,
            ),
      ],
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'WS hello triggers RefreshChannels',
      build: () {
        when(() => mockRepo.getChannelsForUser(any(), any()))
            .thenAnswer((_) async => const Right(channels));
        return ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo);
      },
      act: (bloc) async {
        bloc.add(const LoadChannels(userId: 'user1', teamId: 'team1'));
        await Future.delayed(const Duration(milliseconds: 50));
        // Simulate WS reconnect hello
        bloc.add(const ChannelWsEvent(wsEvent: WsEvent(
          event: WsEventType.hello,
          data: {},
        )));
      },
      wait: const Duration(milliseconds: 200),
      verify: (bloc) {
        // getChannelsForUser should be called twice: initial load + hello refresh
        verify(() => mockRepo.getChannelsForUser('user1', 'team1')).called(2);
      },
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'WS channel_member_updated updates mute status',
      build: () => ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo),
      seed: () => const ChannelsState(
        channels: [
          Channel(
            id: 'ch1',
            name: 'general',
            displayName: 'General',
            totalMsgCount: 10,
            msgCount: 5,
            isMuted: false,
            lastPostAt: 3000,
          ),
        ],
        filteredChannels: [
          Channel(
            id: 'ch1',
            name: 'general',
            displayName: 'General',
            totalMsgCount: 10,
            msgCount: 5,
            isMuted: false,
            lastPostAt: 3000,
          ),
        ],
      ),
      act: (bloc) async {
        // Set _userId via LoadChannels
        when(() => mockRepo.getChannelsForUser(any(), any()))
            .thenAnswer((_) async => const Right([
                  Channel(
                    id: 'ch1',
                    name: 'general',
                    displayName: 'General',
                    totalMsgCount: 10,
                    msgCount: 5,
                    isMuted: false,
                    lastPostAt: 3000,
                  ),
                ]));
        bloc.add(const LoadChannels(userId: 'user1', teamId: 'team1'));
        await Future.delayed(const Duration(milliseconds: 50));
        // Mute via WS
        bloc.add(ChannelWsEvent(wsEvent: WsEvent(
          event: WsEventType.channelMemberUpdated,
          data: {
            'channelMember': jsonEncode({
              'channel_id': 'ch1',
              'user_id': 'user1',
              'notify_props': {'mark_unread': 'mention'},
            }),
          },
        )));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        // LoadChannels loading
        isA<ChannelsState>().having((s) => s.isLoading, 'isLoading', true),
        // LoadChannels loaded
        isA<ChannelsState>().having((s) => s.isLoading, 'isLoading', false),
        // After channel_member_updated: channel is muted
        isA<ChannelsState>().having(
          (s) => s.channels.first.isMuted,
          'isMuted',
          true,
        ),
      ],
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'Muted channel hasUnread returns false',
      build: () => ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo),
      seed: () => const ChannelsState(
        channels: [
          Channel(
            id: 'ch1',
            name: 'general',
            displayName: 'General',
            totalMsgCount: 10,
            msgCount: 5,
            isMuted: true,
            lastPostAt: 3000,
          ),
        ],
        filteredChannels: [
          Channel(
            id: 'ch1',
            name: 'general',
            displayName: 'General',
            totalMsgCount: 10,
            msgCount: 5,
            isMuted: true,
            lastPostAt: 3000,
          ),
        ],
      ),
      verify: (bloc) {
        final ch = bloc.state.channels.first;
        expect(ch.hasUnread, false);
        expect(ch.unreadCount, 0);
        expect(ch.hasMention, false);
      },
    );

    blocTest<ChannelsBloc, ChannelsState>(
      'WS posted root post increments CRT root counters',
      build: () => ChannelsBloc(channelRepository: mockRepo, userRepository: mockUserRepo),
      seed: () => const ChannelsState(
        channels: [
          Channel(
            id: 'ch1',
            name: 'general',
            displayName: 'General',
            totalMsgCount: 10,
            msgCount: 10,
            totalMsgCountRoot: 8,
            msgCountRoot: 8,
            lastPostAt: 3000,
          ),
        ],
        filteredChannels: [
          Channel(
            id: 'ch1',
            name: 'general',
            displayName: 'General',
            totalMsgCount: 10,
            msgCount: 10,
            totalMsgCountRoot: 8,
            msgCountRoot: 8,
            lastPostAt: 3000,
          ),
        ],
      ),
      act: (bloc) {
        final post = jsonEncode({
          'id': 'p1',
          'channel_id': 'ch1',
          'user_id': 'other_user',
          'create_at': 5000,
        });
        bloc.add(ChannelWsEvent(wsEvent: WsEvent(
          event: WsEventType.posted,
          data: {'post': post},
          broadcast: {'channel_id': 'ch1'},
        )));
      },
      expect: () => [
        isA<ChannelsState>()
            .having(
              (s) => s.channels.first.totalMsgCountRoot,
              'totalMsgCountRoot incremented',
              9,
            )
            .having(
              (s) => s.channels.first.unreadCountRoot,
              'unreadCountRoot is 1',
              1,
            ),
      ],
    );
  });
}
