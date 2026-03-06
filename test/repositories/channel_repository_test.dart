import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/exceptions.dart';
import 'package:mgmess/core/error/failures.dart';
import 'package:mgmess/core/network/network_info.dart';
import 'package:mgmess/data/datasources/local/channel_category_local_datasource.dart';
import 'package:mgmess/data/datasources/local/channel_local_datasource.dart';
import 'package:mgmess/data/datasources/remote/channel_remote_datasource.dart';
import 'package:mgmess/data/datasources/remote/user_remote_datasource.dart';
import 'package:mgmess/data/models/channel_model.dart';
import 'package:mgmess/data/models/channel_stats_model.dart';
import 'package:mgmess/data/models/user_model.dart';
import 'package:mgmess/data/repositories/channel_repository_impl.dart';
import 'package:mgmess/domain/entities/channel.dart';

class MockChannelRemoteDataSource extends Mock
    implements ChannelRemoteDataSource {}

class MockChannelLocalDataSource extends Mock
    implements ChannelLocalDataSource {}

class MockChannelCategoryLocalDataSource extends Mock
    implements ChannelCategoryLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockUserRemoteDataSource extends Mock
    implements UserRemoteDataSource {}

void main() {
  late MockChannelRemoteDataSource mockRemote;
  late MockChannelLocalDataSource mockLocal;
  late MockChannelCategoryLocalDataSource mockCategoryLocal;
  late MockNetworkInfo mockNetworkInfo;
  late MockUserRemoteDataSource mockUserRemote;
  late ChannelRepositoryImpl repository;

  setUp(() {
    mockRemote = MockChannelRemoteDataSource();
    mockLocal = MockChannelLocalDataSource();
    mockCategoryLocal = MockChannelCategoryLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    mockUserRemote = MockUserRemoteDataSource();
    repository = ChannelRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
      categoryLocalDataSource: mockCategoryLocal,
      networkInfo: mockNetworkInfo,
      userRemoteDataSource: mockUserRemote,
    );
  });

  setUpAll(() {
    registerFallbackValue(<Channel>[]);
  });

  const testChannel1 = ChannelModel(
    id: 'ch1',
    teamId: 'team1',
    name: 'general',
    displayName: 'General',
    type: ChannelType.open,
    totalMsgCount: 100,
    totalMsgCountRoot: 80,
    lastPostAt: 1700000000000,
  );

  const testChannel2 = ChannelModel(
    id: 'ch2',
    teamId: 'team1',
    name: 'random',
    displayName: 'Random',
    type: ChannelType.open,
    totalMsgCount: 50,
    totalMsgCountRoot: 40,
  );

  const directChannel = ChannelModel(
    id: 'dm1',
    name: 'user1__user2',
    displayName: 'user2',
    type: ChannelType.direct,
  );

  group('ChannelRepositoryImpl', () {
    group('getChannelsForUser', () {
      test('returns enriched channels from remote when online', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockRemote.getChannelsForUser(any(), any()))
            .thenAnswer((_) async => [testChannel1, testChannel2]);
        when(() => mockRemote.getChannelMembersForUser(any(), any()))
            .thenAnswer((_) async => [
                  {
                    'channel_id': 'ch1',
                    'msg_count': 95,
                    'msg_count_root': 75,
                    'mention_count': 2,
                    'mention_count_root': 1,
                    'urgent_mention_count': 0,
                    'last_viewed_at': 1699999990000,
                    'notify_props': {'mark_unread': 'all'},
                  },
                  {
                    'channel_id': 'ch2',
                    'msg_count': 50,
                    'msg_count_root': 40,
                    'mention_count': 0,
                    'mention_count_root': 0,
                    'urgent_mention_count': 0,
                    'last_viewed_at': 1700000000000,
                    'notify_props': {'mark_unread': 'mention'},
                  },
                ]);
        when(() => mockLocal.cacheChannels(any()))
            .thenAnswer((_) async {});

        final result =
            await repository.getChannelsForUser('user1', 'team1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (channels) {
            expect(channels, hasLength(2));

            // ch1: enriched with membership
            expect(channels[0].id, 'ch1');
            expect(channels[0].msgCount, 95);
            expect(channels[0].mentionCount, 2);
            expect(channels[0].lastViewedAt, 1699999990000);
            expect(channels[0].isMuted, false);
            expect(channels[0].unreadCount, 5); // 100 - 95

            // ch2: muted channel
            expect(channels[1].id, 'ch2');
            expect(channels[1].msgCount, 50);
            expect(channels[1].mentionCount, 0);
            expect(channels[1].isMuted, true);
          },
        );
      });

      test('returns channels without enrichment when batch members fails',
          () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockRemote.getChannelsForUser(any(), any()))
            .thenAnswer((_) async => [testChannel1]);
        when(() => mockRemote.getChannelMembersForUser(any(), any()))
            .thenThrow(
                const ServerException(message: 'Members failed'));
        when(() => mockLocal.cacheChannels(any()))
            .thenAnswer((_) async {});

        final result =
            await repository.getChannelsForUser('user1', 'team1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (channels) {
            expect(channels, hasLength(1));
            expect(channels[0].id, 'ch1');
            // No enrichment — defaults
            expect(channels[0].msgCount, 0);
            expect(channels[0].mentionCount, 0);
            expect(channels[0].isMuted, false);
          },
        );
      });

      test('returns cached channels when offline', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => false);
        when(() => mockLocal.getAllChannels())
            .thenAnswer((_) async => [testChannel1]);

        final result =
            await repository.getChannelsForUser('user1', 'team1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (channels) {
            expect(channels, hasLength(1));
            expect(channels[0].id, 'ch1');
          },
        );
        verifyNever(() => mockRemote.getChannelsForUser(any(), any()));
      });

      test('falls back to cache on ServerException when cache is not empty',
          () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockRemote.getChannelsForUser(any(), any()))
            .thenThrow(
                const ServerException(message: 'Server error'));
        when(() => mockLocal.getAllChannels())
            .thenAnswer((_) async => [testChannel1]);

        final result =
            await repository.getChannelsForUser('user1', 'team1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (channels) => expect(channels, hasLength(1)),
        );
      });

      test('returns ServerFailure on ServerException when cache is empty',
          () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockRemote.getChannelsForUser(any(), any()))
            .thenThrow(
                const ServerException(message: 'Server error'));
        when(() => mockLocal.getAllChannels())
            .thenAnswer((_) async => []);

        final result =
            await repository.getChannelsForUser('user1', 'team1');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns CacheFailure on CacheException', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => false);
        when(() => mockLocal.getAllChannels())
            .thenThrow(const CacheException(message: 'DB error'));

        final result =
            await repository.getChannelsForUser('user1', 'team1');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('getChannel', () {
      test('returns channel on success', () async {
        when(() => mockRemote.getChannel(any()))
            .thenAnswer((_) async => testChannel1);

        final result = await repository.getChannel('ch1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (channel) {
            expect(channel.id, 'ch1');
            expect(channel.displayName, 'General');
          },
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.getChannel(any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.getChannel('ch1');

        expect(result.isLeft(), true);
      });
    });

    group('viewChannel', () {
      test('returns Right(null) on success', () async {
        when(() => mockRemote.viewChannel(any(), any()))
            .thenAnswer((_) async {});

        final result =
            await repository.viewChannel('user1', 'ch1');

        expect(result.isRight(), true);
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.viewChannel(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result =
            await repository.viewChannel('user1', 'ch1');

        expect(result.isLeft(), true);
      });
    });

    group('createDirectChannel', () {
      test('returns channel on success', () async {
        when(() => mockRemote.createDirectChannel(any(), any()))
            .thenAnswer((_) async => directChannel);

        final result =
            await repository.createDirectChannel('user1', 'user2');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (channel) {
            expect(channel.id, 'dm1');
            expect(channel.type, ChannelType.direct);
          },
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.createDirectChannel(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result =
            await repository.createDirectChannel('user1', 'user2');

        expect(result.isLeft(), true);
      });
    });

    group('muteChannel', () {
      test('returns Right(null) on success', () async {
        when(() => mockRemote.updateChannelNotifyProps(
              any(),
              any(),
              any(),
            )).thenAnswer((_) async {});

        final result =
            await repository.muteChannel('ch1', 'user1');

        expect(result.isRight(), true);
        verify(() => mockRemote.updateChannelNotifyProps(
              'ch1',
              'user1',
              {'mark_unread': 'mention'},
            )).called(1);
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.updateChannelNotifyProps(
              any(),
              any(),
              any(),
            )).thenThrow(const ServerException(message: 'Error'));

        final result =
            await repository.muteChannel('ch1', 'user1');

        expect(result.isLeft(), true);
      });
    });

    group('unmuteChannel', () {
      test('returns Right(null) on success', () async {
        when(() => mockRemote.updateChannelNotifyProps(
              any(),
              any(),
              any(),
            )).thenAnswer((_) async {});

        final result =
            await repository.unmuteChannel('ch1', 'user1');

        expect(result.isRight(), true);
        verify(() => mockRemote.updateChannelNotifyProps(
              'ch1',
              'user1',
              {'mark_unread': 'all'},
            )).called(1);
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.updateChannelNotifyProps(
              any(),
              any(),
              any(),
            )).thenThrow(const ServerException(message: 'Error'));

        final result =
            await repository.unmuteChannel('ch1', 'user1');

        expect(result.isLeft(), true);
      });
    });

    group('getChannelStats', () {
      test('returns ChannelStats on success', () async {
        when(() => mockRemote.getChannelStats(any()))
            .thenAnswer((_) async => const ChannelStatsModel(
                  channelId: 'ch1',
                  memberCount: 42,
                  guestCount: 2,
                  pinnedPostCount: 5,
                ));

        final result = await repository.getChannelStats('ch1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (stats) {
            expect(stats.channelId, 'ch1');
            expect(stats.memberCount, 42);
            expect(stats.guestCount, 2);
            expect(stats.pinnedPostCount, 5);
          },
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.getChannelStats(any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.getChannelStats('ch1');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('getChannelMembers', () {
      test('returns list of channel members with roles on success', () async {
        when(() => mockRemote.getChannelMembers(any(),
                page: any(named: 'page'),
                perPage: any(named: 'perPage')))
            .thenAnswer((_) async => [
                  {'user_id': 'u1', 'channel_id': 'ch1', 'roles': 'channel_admin channel_user'},
                  {'user_id': 'u2', 'channel_id': 'ch1', 'roles': 'channel_user'},
                ]);
        when(() => mockUserRemote.getUsersByIds(any()))
            .thenAnswer((_) async => [
                  const UserModel(id: 'u1', username: 'admin'),
                  const UserModel(id: 'u2', username: 'member'),
                ]);

        final result = await repository.getChannelMembers('ch1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (members) {
            expect(members.length, 2);
            expect(members[0].user.id, 'u1');
            expect(members[0].isChannelAdmin, true);
            expect(members[1].user.id, 'u2');
            expect(members[1].isChannelAdmin, false);
          },
        );
        verify(() => mockUserRemote.getUsersByIds(['u1', 'u2'])).called(1);
      });

      test('returns empty list when no members', () async {
        when(() => mockRemote.getChannelMembers(any(),
                page: any(named: 'page'),
                perPage: any(named: 'perPage')))
            .thenAnswer((_) async => []);

        final result = await repository.getChannelMembers('ch1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (users) => expect(users, isEmpty),
        );
        verifyNever(() => mockUserRemote.getUsersByIds(any()));
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.getChannelMembers(any(),
                page: any(named: 'page'),
                perPage: any(named: 'perPage')))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.getChannelMembers('ch1');

        expect(result.isLeft(), true);
      });
    });

    group('leaveChannel', () {
      test('returns Right(null) on success', () async {
        when(() => mockRemote.leaveChannel(any(), any()))
            .thenAnswer((_) async {});

        final result =
            await repository.leaveChannel('ch1', 'user1');

        expect(result.isRight(), true);
        verify(() => mockRemote.leaveChannel('ch1', 'user1')).called(1);
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.leaveChannel(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result =
            await repository.leaveChannel('ch1', 'user1');

        expect(result.isLeft(), true);
      });
    });
  });
}
