import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mgmess/app.dart';
import 'package:mgmess/domain/entities/channel.dart';
import 'package:mgmess/domain/entities/post.dart';
import 'package:mgmess/domain/entities/user.dart';

import '../fixtures/test_data.dart';
import 'test_di.dart';

/// Результат создания тестового приложения.
class TestAppResult {
  final App app;
  final TestMocks mocks;

  const TestAppResult({required this.app, required this.mocks});
}

/// Инициализирует зависимости и возвращает App + моки.
Future<TestAppResult> createTestApp() async {
  final mocks = await initTestDependencies();
  return TestAppResult(app: const App(), mocks: mocks);
}

/// Настраивает моки для авторизованного пользователя.
/// После этого AuthCheckSession → AuthAuthenticated.
void setupAuthenticatedState(TestMocks mocks) {
  when(() => mocks.authRepository.hasValidSession())
      .thenAnswer((_) async => true);
  when(() => mocks.authRepository.getCurrentUser())
      .thenAnswer((_) async => const Right(testUser));
  when(() => mocks.authRepository.getMyTeams())
      .thenAnswer((_) async => const Right([testTeam]));
  when(() => mocks.authRepository.getClientConfig())
      .thenAnswer((_) async => const Right({
            'EnableSignInWithEmail': 'true',
            'EnableSignInWithUsername': 'true',
            'EnableSignUpWithGitLab': 'true',
          }));
}

/// Настраивает моки для неавторизованного пользователя.
void setupUnauthenticatedState(TestMocks mocks) {
  when(() => mocks.authRepository.hasValidSession())
      .thenAnswer((_) async => false);
  when(() => mocks.authRepository.getClientConfig())
      .thenAnswer((_) async => const Right({
            'EnableSignInWithEmail': 'true',
            'EnableSignInWithUsername': 'true',
            'EnableSignUpWithGitLab': 'true',
          }));
}

/// Настраивает моки для загрузки каналов.
void setupChannelList(TestMocks mocks, {List<Channel>? channels}) {
  when(() => mocks.channelRepository.getChannelsForUser(any(), any()))
      .thenAnswer((_) async => Right(channels ?? testChannels));
  when(() => mocks.channelRepository.viewChannel(any(), any()))
      .thenAnswer((_) async => const Right(null));
}

/// Настраивает моки для загрузки постов в канале.
void setupChannelPosts(
  TestMocks mocks, {
  List<Post>? posts,
  String? channelId,
}) {
  when(() => mocks.postRepository.getCachedChannelPosts(
        channelId ?? any(),
        perPage: any(named: 'perPage'),
      )).thenAnswer((_) async => const Right(<Post>[]));
  when(() => mocks.postRepository.getChannelPosts(
        channelId ?? any(),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        before: any(named: 'before'),
        after: any(named: 'after'),
      )).thenAnswer((_) async => Right(posts ?? testPosts));
}

/// Настраивает мок для отправки сообщения.
void setupSendMessage(TestMocks mocks, {Post? resultPost}) {
  when(() => mocks.postRepository.createPost(
        channelId: any(named: 'channelId'),
        message: any(named: 'message'),
        rootId: any(named: 'rootId'),
        fileIds: any(named: 'fileIds'),
        priority: any(named: 'priority'),
      )).thenAnswer((_) async => Right(resultPost ?? testNewPost));
}

/// Настраивает мок для login.
void setupLogin(TestMocks mocks, {User? user}) {
  when(() => mocks.authRepository.login(
        loginId: any(named: 'loginId'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => Right(user ?? testUser));
  when(() => mocks.authRepository.getMyTeams())
      .thenAnswer((_) async => const Right([testTeam]));
  when(() => mocks.authRepository.saveAuthTokens(
        token: any(named: 'token'),
        csrfToken: any(named: 'csrfToken'),
      )).thenAnswer((_) async => const Right(null));
}

/// Настраивает моки для pin/unpin.
void setupPinMessage(TestMocks mocks) {
  when(() => mocks.postRepository.pinPost(any())).thenAnswer(
    (invocation) async {
      final postId = invocation.positionalArguments[0] as String;
      return Right(Post(id: postId, channelId: 'ch-001', userId: 'user-001'));
    },
  );
  when(() => mocks.postRepository.unpinPost(any())).thenAnswer(
    (invocation) async {
      final postId = invocation.positionalArguments[0] as String;
      return Right(Post(id: postId, channelId: 'ch-001', userId: 'user-001'));
    },
  );
}

/// Настраивает моки для удаления сообщения.
void setupDeleteMessage(TestMocks mocks) {
  when(() => mocks.postRepository.deletePost(any()))
      .thenAnswer((_) async => const Right(null));
}

/// Настраивает моки для редактирования сообщения.
void setupEditMessage(TestMocks mocks) {
  when(() => mocks.postRepository.editPost(any(), any())).thenAnswer(
    (invocation) async {
      final postId = invocation.positionalArguments[0] as String;
      final message = invocation.positionalArguments[1] as String;
      return Right(Post(
        id: postId,
        channelId: 'ch-001',
        userId: 'user-001',
        message: message,
        editAt: DateTime.now().millisecondsSinceEpoch,
      ));
    },
  );
}

/// Настраивает моки для получения треда.
void setupThread(TestMocks mocks, {List<Post>? posts}) {
  when(() => mocks.postRepository.getPostThread(any())).thenAnswer(
    (_) async => Right(posts ?? testPosts),
  );
}

/// Настраивает моки для pinned posts.
void setupPinnedPosts(TestMocks mocks, {List<Post>? posts}) {
  when(() => mocks.postRepository.getPinnedPosts(any())).thenAnswer(
    (_) async => Right(posts ?? [testPinnedPost]),
  );
}
