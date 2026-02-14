import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/failures.dart';
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
  });
}
