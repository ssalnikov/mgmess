import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/failures.dart';
import 'package:mgmess/core/network/websocket_events.dart';
import 'package:mgmess/domain/entities/channel.dart';
import 'package:mgmess/domain/repositories/channel_repository.dart';
import 'package:mgmess/presentation/screens/channels/channels_bloc.dart';

class MockChannelRepository extends Mock implements ChannelRepository {}

void main() {
  late MockChannelRepository mockRepo;

  setUp(() {
    mockRepo = MockChannelRepository();
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
        return ChannelsBloc(channelRepository: mockRepo);
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
        return ChannelsBloc(channelRepository: mockRepo);
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
      build: () => ChannelsBloc(channelRepository: mockRepo),
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
      build: () => ChannelsBloc(channelRepository: mockRepo),
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
        return ChannelsBloc(channelRepository: mockRepo);
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
      build: () => ChannelsBloc(channelRepository: mockRepo),
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
      'MarkChannelAsRead updates lastViewedAt to current time',
      build: () {
        when(() => mockRepo.viewChannel(any(), any()))
            .thenAnswer((_) async => const Right(null));
        return ChannelsBloc(channelRepository: mockRepo);
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
  });
}
