import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/exceptions.dart';
import 'package:mgmess/core/error/failures.dart';
import 'package:mgmess/core/network/network_info.dart';
import 'package:mgmess/data/datasources/local/post_local_datasource.dart';
import 'package:mgmess/data/datasources/remote/command_remote_datasource.dart';
import 'package:mgmess/data/datasources/remote/post_remote_datasource.dart';
import 'package:mgmess/data/models/post_model.dart';
import 'package:mgmess/data/models/user_thread_model.dart';
import 'package:mgmess/data/repositories/post_repository_impl.dart';
import 'package:mgmess/domain/entities/post.dart';

class MockPostRemoteDataSource extends Mock implements PostRemoteDataSource {}

class MockPostLocalDataSource extends Mock implements PostLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockCommandRemoteDataSource extends Mock
    implements CommandRemoteDataSource {}

void main() {
  late MockPostRemoteDataSource mockRemote;
  late MockPostLocalDataSource mockLocal;
  late MockCommandRemoteDataSource mockCommand;
  late MockNetworkInfo mockNetworkInfo;
  late PostRepositoryImpl repository;

  setUp(() {
    mockRemote = MockPostRemoteDataSource();
    mockLocal = MockPostLocalDataSource();
    mockCommand = MockCommandRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = PostRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
      commandDataSource: mockCommand,
      networkInfo: mockNetworkInfo,
    );
  });

  setUpAll(() {
    registerFallbackValue(<Post>[]);
    registerFallbackValue(const Post(id: '', channelId: '', userId: ''));
  });

  const testPost = PostModel(
    id: 'post1',
    channelId: 'ch1',
    userId: 'user1',
    message: 'Hello',
    createAt: 1700000000000,
  );

  const testPost2 = PostModel(
    id: 'post2',
    channelId: 'ch1',
    userId: 'user2',
    message: 'World',
    createAt: 1700000001000,
  );

  const editedPost = PostModel(
    id: 'post1',
    channelId: 'ch1',
    userId: 'user1',
    message: 'Edited',
    editAt: 1700000002000,
  );

  const pinnedPost = PostModel(
    id: 'post1',
    channelId: 'ch1',
    userId: 'user1',
    message: 'Hello',
    isPinned: true,
  );

  const testThread = UserThreadModel(
    id: 'thread1',
    replyCount: 3,
    lastReplyAt: 1700000000000,
    lastViewedAt: 1700000000000,
    participantIds: ['user1', 'user2'],
    post: testPost,
    unreadReplies: 1,
    unreadMentions: 0,
  );

  group('PostRepositoryImpl', () {
    group('getChannelPosts', () {
      test('returns posts from remote when online', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockRemote.getChannelPosts(
              any(),
              page: any(named: 'page'),
              perPage: any(named: 'perPage'),
              before: any(named: 'before'),
              after: any(named: 'after'),
            )).thenAnswer((_) async => [testPost, testPost2]);
        when(() => mockLocal.cachePosts(any()))
            .thenAnswer((_) async {});

        final result = await repository.getChannelPosts('ch1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (posts) {
            expect(posts, hasLength(2));
            expect(posts[0].id, 'post1');
            expect(posts[1].id, 'post2');
          },
        );
        verify(() => mockRemote.getChannelPosts(
              'ch1',
              page: 0,
              perPage: 60,
              before: null,
              after: null,
            )).called(1);
      });

      test('returns cached posts when offline', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => false);
        when(() => mockLocal.getChannelPosts(
              any(),
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            )).thenAnswer((_) async => [testPost]);

        final result = await repository.getChannelPosts('ch1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (posts) {
            expect(posts, hasLength(1));
            expect(posts[0].id, 'post1');
          },
        );
        verifyNever(() => mockRemote.getChannelPosts(
              any(),
              page: any(named: 'page'),
              perPage: any(named: 'perPage'),
            ));
      });

      test('falls back to cache on ServerException when cache is not empty',
          () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockRemote.getChannelPosts(
              any(),
              page: any(named: 'page'),
              perPage: any(named: 'perPage'),
              before: any(named: 'before'),
              after: any(named: 'after'),
            )).thenThrow(const ServerException(message: 'Server error'));
        when(() => mockLocal.getChannelPosts(
              any(),
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            )).thenAnswer((_) async => [testPost]);

        final result = await repository.getChannelPosts('ch1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (posts) => expect(posts, hasLength(1)),
        );
      });

      test('returns ServerFailure on ServerException when cache is empty',
          () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockRemote.getChannelPosts(
              any(),
              page: any(named: 'page'),
              perPage: any(named: 'perPage'),
              before: any(named: 'before'),
              after: any(named: 'after'),
            )).thenThrow(const ServerException(message: 'Server error'));
        when(() => mockLocal.getChannelPosts(
              any(),
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            )).thenAnswer((_) async => []);

        final result = await repository.getChannelPosts('ch1');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns CacheFailure on CacheException', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => false);
        when(() => mockLocal.getChannelPosts(
              any(),
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            )).thenThrow(const CacheException(message: 'DB error'));

        final result = await repository.getChannelPosts('ch1');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('createPost', () {
      test('creates post via remote when online', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockRemote.createPost(
              channelId: any(named: 'channelId'),
              message: any(named: 'message'),
              rootId: any(named: 'rootId'),
              fileIds: any(named: 'fileIds'),
              priority: any(named: 'priority'),
            )).thenAnswer((_) async => testPost);
        when(() => mockLocal.cachePosts(any()))
            .thenAnswer((_) async {});

        final result = await repository.createPost(
          channelId: 'ch1',
          message: 'Hello',
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (post) => expect(post.id, 'post1'),
        );
      });

      test('saves pending post when offline', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => false);
        when(() => mockLocal.savePendingPost(any()))
            .thenAnswer((_) async {});

        final result = await repository.createPost(
          channelId: 'ch1',
          message: 'Offline msg',
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (post) {
            expect(post.id, startsWith('pending_'));
            expect(post.channelId, 'ch1');
            expect(post.message, 'Offline msg');
            expect(post.pendingId, post.id);
          },
        );
        verify(() => mockLocal.savePendingPost(any())).called(1);
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockRemote.createPost(
              channelId: any(named: 'channelId'),
              message: any(named: 'message'),
              rootId: any(named: 'rootId'),
              fileIds: any(named: 'fileIds'),
              priority: any(named: 'priority'),
            )).thenThrow(const ServerException(message: 'Error'));

        final result = await repository.createPost(
          channelId: 'ch1',
          message: 'Hello',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('getPost', () {
      test('returns post on success', () async {
        when(() => mockRemote.getPost(any()))
            .thenAnswer((_) async => testPost);

        final result = await repository.getPost('post1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (post) => expect(post.id, 'post1'),
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.getPost(any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.getPost('post1');

        expect(result.isLeft(), true);
      });
    });

    group('editPost', () {
      test('returns edited post on success', () async {
        when(() => mockRemote.editPost(any(), any()))
            .thenAnswer((_) async => editedPost);
        when(() => mockLocal.cachePosts(any()))
            .thenAnswer((_) async {});

        final result = await repository.editPost('post1', 'Edited');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (post) {
            expect(post.message, 'Edited');
          },
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.editPost(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.editPost('post1', 'Edited');

        expect(result.isLeft(), true);
      });
    });

    group('deletePost', () {
      test('returns Right(null) on success', () async {
        when(() => mockRemote.deletePost(any()))
            .thenAnswer((_) async {});
        when(() => mockLocal.deletePost(any()))
            .thenAnswer((_) async {});

        final result = await repository.deletePost('post1');

        expect(result.isRight(), true);
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.deletePost(any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.deletePost('post1');

        expect(result.isLeft(), true);
      });
    });

    group('getPostThread', () {
      test('returns posts on success', () async {
        when(() => mockRemote.getPostThread(any()))
            .thenAnswer((_) async => [testPost, testPost2]);

        final result = await repository.getPostThread('post1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (posts) => expect(posts, hasLength(2)),
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.getPostThread(any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.getPostThread('post1');

        expect(result.isLeft(), true);
      });
    });

    group('pinPost', () {
      test('returns pinned post on success', () async {
        when(() => mockRemote.pinPost(any()))
            .thenAnswer((_) async => pinnedPost);

        final result = await repository.pinPost('post1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (post) => expect(post.isPinned, true),
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.pinPost(any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.pinPost('post1');

        expect(result.isLeft(), true);
      });
    });

    group('unpinPost', () {
      test('returns unpinned post on success', () async {
        when(() => mockRemote.unpinPost(any()))
            .thenAnswer((_) async => testPost);

        final result = await repository.unpinPost('post1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (post) => expect(post.isPinned, false),
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.unpinPost(any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.unpinPost('post1');

        expect(result.isLeft(), true);
      });
    });

    group('flagPost', () {
      test('returns Right(null) on success', () async {
        when(() => mockRemote.flagPost(any(), any()))
            .thenAnswer((_) async {});

        final result = await repository.flagPost('user1', 'post1');

        expect(result.isRight(), true);
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.flagPost(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.flagPost('user1', 'post1');

        expect(result.isLeft(), true);
      });
    });

    group('unflagPost', () {
      test('returns Right(null) on success', () async {
        when(() => mockRemote.unflagPost(any(), any()))
            .thenAnswer((_) async {});

        final result = await repository.unflagPost('user1', 'post1');

        expect(result.isRight(), true);
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.unflagPost(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.unflagPost('user1', 'post1');

        expect(result.isLeft(), true);
      });
    });

    group('getFlaggedPosts', () {
      test('returns posts on success', () async {
        when(() => mockRemote.getFlaggedPosts(
              any(),
              page: any(named: 'page'),
              perPage: any(named: 'perPage'),
            )).thenAnswer((_) async => [testPost]);

        final result = await repository.getFlaggedPosts('user1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (posts) => expect(posts, hasLength(1)),
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.getFlaggedPosts(
              any(),
              page: any(named: 'page'),
              perPage: any(named: 'perPage'),
            )).thenThrow(const ServerException(message: 'Error'));

        final result = await repository.getFlaggedPosts('user1');

        expect(result.isLeft(), true);
      });
    });

    group('searchPosts', () {
      test('returns posts on success', () async {
        when(() => mockRemote.searchPosts(any(), any()))
            .thenAnswer((_) async => [testPost]);

        final result = await repository.searchPosts('team1', 'query');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (posts) => expect(posts, hasLength(1)),
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.searchPosts(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.searchPosts('team1', 'query');

        expect(result.isLeft(), true);
      });
    });

    group('getPinnedPosts', () {
      test('returns pinned posts on success', () async {
        when(() => mockRemote.getPinnedPosts(any()))
            .thenAnswer((_) async => [pinnedPost]);

        final result = await repository.getPinnedPosts('ch1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (posts) {
            expect(posts, hasLength(1));
            expect(posts[0].isPinned, true);
          },
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.getPinnedPosts(any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.getPinnedPosts('ch1');

        expect(result.isLeft(), true);
      });
    });

    group('getUserThreads', () {
      test('returns threads on success', () async {
        when(() => mockRemote.getUserThreads(
              any(),
              any(),
              perPage: any(named: 'perPage'),
              before: any(named: 'before'),
            )).thenAnswer((_) async => [testThread]);

        final result =
            await repository.getUserThreads('user1', 'team1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (threads) {
            expect(threads, hasLength(1));
            expect(threads[0].id, 'thread1');
          },
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.getUserThreads(
              any(),
              any(),
              perPage: any(named: 'perPage'),
              before: any(named: 'before'),
            )).thenThrow(const ServerException(message: 'Error'));

        final result =
            await repository.getUserThreads('user1', 'team1');

        expect(result.isLeft(), true);
      });
    });
  });
}
