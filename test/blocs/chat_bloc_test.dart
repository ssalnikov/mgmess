import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/failures.dart';
import 'package:mgmess/domain/entities/post.dart';
import 'package:mgmess/domain/repositories/post_repository.dart';
import 'package:mgmess/domain/services/ws_post_parser.dart';
import 'package:mgmess/presentation/screens/chat/chat_bloc.dart';

class MockPostRepository extends Mock implements PostRepository {}

class MockWsPostParser extends Mock implements WsPostParser {}

void main() {
  late MockPostRepository mockRepo;
  late MockWsPostParser mockParser;

  setUp(() {
    mockRepo = MockPostRepository();
    mockParser = MockWsPostParser();
  });

  const posts = [
    Post(id: 'p1', channelId: 'ch1', userId: 'u1', message: 'Hello', createAt: 3000),
    Post(id: 'p2', channelId: 'ch1', userId: 'u2', message: 'Hi', createAt: 2000),
  ];

  group('ChatBloc', () {
    blocTest<ChatBloc, ChatState>(
      'emits [loading, loaded] when LoadPosts succeeds',
      build: () {
        when(() => mockRepo.getChannelPosts(any()))
            .thenAnswer((_) async => const Right(posts));
        return ChatBloc(postRepository: mockRepo, wsPostParser: mockParser, userId: 'u1');
      },
      act: (bloc) => bloc.add(const LoadPosts(channelId: 'ch1')),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.isLoading, 'isLoading', true)
            .having((s) => s.channelId, 'channelId', 'ch1'),
        isA<ChatState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.posts.length, 'posts.length', 2),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [loading, error] when LoadPosts fails',
      build: () {
        when(() => mockRepo.getChannelPosts(any()))
            .thenAnswer((_) async =>
                const Left(ServerFailure(message: 'Failed')));
        return ChatBloc(postRepository: mockRepo, wsPostParser: mockParser, userId: 'u1');
      },
      act: (bloc) => bloc.add(const LoadPosts(channelId: 'ch1')),
      expect: () => [
        isA<ChatState>().having((s) => s.isLoading, 'isLoading', true),
        isA<ChatState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.error, 'error', 'Failed'),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'SendMessage adds post optimistically',
      build: () {
        when(() => mockRepo.createPost(
              channelId: any(named: 'channelId'),
              message: any(named: 'message'),
              rootId: any(named: 'rootId'),
              fileIds: any(named: 'fileIds'),
            )).thenAnswer((_) async => const Right(
              Post(id: 'p3', channelId: 'ch1', userId: 'u1', message: 'New'),
            ));
        return ChatBloc(postRepository: mockRepo, wsPostParser: mockParser, userId: 'u1');
      },
      seed: () => ChatState(channelId: 'ch1', posts: posts),
      act: (bloc) => bloc.add(const SendMessage(message: 'New')),
      expect: () => [
        isA<ChatState>().having((s) => s.isSending, 'isSending', true),
        isA<ChatState>()
            .having((s) => s.isSending, 'isSending', false)
            .having((s) => s.posts.length, 'posts.length', 3)
            .having((s) => s.posts.first.message, 'first message', 'New'),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'DeleteMessage removes post from list',
      build: () {
        when(() => mockRepo.deletePost(any()))
            .thenAnswer((_) async => const Right(null));
        return ChatBloc(postRepository: mockRepo, wsPostParser: mockParser, userId: 'u1');
      },
      seed: () => ChatState(channelId: 'ch1', posts: posts),
      act: (bloc) => bloc.add(const DeleteMessage(postId: 'p1')),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.posts.length, 'posts.length', 1)
            .having((s) => s.posts.first.id, 'remaining post id', 'p2'),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'AddReaction optimistically adds reaction and calls API',
      build: () {
        when(() => mockRepo.addReaction(any(), any(), any()))
            .thenAnswer((_) async => const Right(null));
        return ChatBloc(postRepository: mockRepo, wsPostParser: mockParser, userId: 'u1');
      },
      seed: () => ChatState(channelId: 'ch1', posts: posts),
      act: (bloc) => bloc.add(const AddReaction(postId: 'p1', emojiName: 'heart')),
      expect: () => [
        isA<ChatState>().having(
          (s) => s.posts.first.reactions['heart'],
          'reaction added',
          ['u1'],
        ),
      ],
      verify: (_) {
        verify(() => mockRepo.addReaction('p1', 'u1', 'heart')).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'RemoveReaction optimistically removes reaction and calls API',
      build: () {
        when(() => mockRepo.removeReaction(any(), any(), any()))
            .thenAnswer((_) async => const Right(null));
        return ChatBloc(postRepository: mockRepo, wsPostParser: mockParser, userId: 'u1');
      },
      seed: () => ChatState(channelId: 'ch1', posts: [
        Post(
          id: 'p1',
          channelId: 'ch1',
          userId: 'u1',
          message: 'Hello',
          createAt: 3000,
          reactions: {'heart': ['u1', 'u2']},
        ),
        posts[1],
      ]),
      act: (bloc) => bloc.add(const RemoveReaction(postId: 'p1', emojiName: 'heart')),
      expect: () => [
        isA<ChatState>().having(
          (s) => s.posts.first.reactions['heart'],
          'user removed',
          ['u2'],
        ),
      ],
      verify: (_) {
        verify(() => mockRepo.removeReaction('p1', 'u1', 'heart')).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'LoadMorePosts does nothing when already loading more',
      build: () => ChatBloc(postRepository: mockRepo, wsPostParser: mockParser, userId: 'u1'),
      seed: () => ChatState(
        channelId: 'ch1',
        posts: posts,
        isLoadingMore: true,
      ),
      act: (bloc) => bloc.add(const LoadMorePosts()),
      expect: () => [],
    );

    blocTest<ChatBloc, ChatState>(
      'LoadMorePosts does nothing when no more posts',
      build: () => ChatBloc(postRepository: mockRepo, wsPostParser: mockParser, userId: 'u1'),
      seed: () => ChatState(
        channelId: 'ch1',
        posts: posts,
        hasMore: false,
      ),
      act: (bloc) => bloc.add(const LoadMorePosts()),
      expect: () => [],
    );
  });
}
