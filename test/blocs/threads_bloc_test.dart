import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/failures.dart';
import 'package:mgmess/domain/entities/post.dart';
import 'package:mgmess/domain/entities/user_thread.dart';
import 'package:mgmess/domain/repositories/post_repository.dart';
import 'package:mgmess/presentation/screens/threads/threads_bloc.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late MockPostRepository mockRepo;

  setUp(() {
    mockRepo = MockPostRepository();
  });

  const threads = [
    UserThread(
      id: 't1',
      replyCount: 3,
      lastReplyAt: 5000,
      lastViewedAt: 4000,
      participantIds: ['u1', 'u2'],
      post: Post(id: 't1', channelId: 'ch1', userId: 'u1', message: 'Thread 1'),
      unreadReplies: 1,
      unreadMentions: 0,
    ),
    UserThread(
      id: 't2',
      replyCount: 1,
      lastReplyAt: 3000,
      lastViewedAt: 3000,
      participantIds: ['u1'],
      post: Post(id: 't2', channelId: 'ch1', userId: 'u2', message: 'Thread 2'),
      unreadReplies: 0,
      unreadMentions: 0,
    ),
  ];

  group('ThreadsBloc', () {
    blocTest<ThreadsBloc, ThreadsState>(
      'emits [loading, loaded] when LoadThreads succeeds',
      build: () {
        when(() => mockRepo.getUserThreads(
              any(),
              any(),
              perPage: any(named: 'perPage'),
              before: any(named: 'before'),
            )).thenAnswer((_) async => const Right(threads));
        return ThreadsBloc(postRepository: mockRepo);
      },
      act: (bloc) =>
          bloc.add(const LoadThreads(userId: 'u1', teamId: 'team1')),
      expect: () => [
        isA<ThreadsState>()
            .having((s) => s.isLoading, 'isLoading', true)
            .having((s) => s.userId, 'userId', 'u1')
            .having((s) => s.teamId, 'teamId', 'team1'),
        isA<ThreadsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.threads.length, 'threads.length', 2)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<ThreadsBloc, ThreadsState>(
      'emits [loading, error] when LoadThreads fails',
      build: () {
        when(() => mockRepo.getUserThreads(
              any(),
              any(),
              perPage: any(named: 'perPage'),
              before: any(named: 'before'),
            )).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Failed')));
        return ThreadsBloc(postRepository: mockRepo);
      },
      act: (bloc) =>
          bloc.add(const LoadThreads(userId: 'u1', teamId: 'team1')),
      expect: () => [
        isA<ThreadsState>().having((s) => s.isLoading, 'isLoading', true),
        isA<ThreadsState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.error, 'error', 'Failed'),
      ],
    );

    blocTest<ThreadsBloc, ThreadsState>(
      'LoadMoreThreads appends threads',
      build: () {
        when(() => mockRepo.getUserThreads(
              any(),
              any(),
              perPage: any(named: 'perPage'),
              before: any(named: 'before'),
            )).thenAnswer((_) async => const Right([
              UserThread(
                id: 't3',
                replyCount: 2,
                lastReplyAt: 1000,
                lastViewedAt: 1000,
                participantIds: ['u3'],
                post: Post(
                    id: 't3',
                    channelId: 'ch1',
                    userId: 'u3',
                    message: 'Thread 3'),
                unreadReplies: 0,
                unreadMentions: 0,
              ),
            ]));
        return ThreadsBloc(postRepository: mockRepo);
      },
      seed: () => const ThreadsState(
        threads: threads,
        hasMore: true,
        userId: 'u1',
        teamId: 'team1',
      ),
      act: (bloc) => bloc.add(const LoadMoreThreads()),
      expect: () => [
        isA<ThreadsState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', true),
        isA<ThreadsState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', false)
            .having((s) => s.threads.length, 'threads.length', 3)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<ThreadsBloc, ThreadsState>(
      'LoadMoreThreads does nothing when hasMore is false',
      build: () => ThreadsBloc(postRepository: mockRepo),
      seed: () => const ThreadsState(
        threads: threads,
        hasMore: false,
        userId: 'u1',
        teamId: 'team1',
      ),
      act: (bloc) => bloc.add(const LoadMoreThreads()),
      expect: () => [],
    );
  });
}
