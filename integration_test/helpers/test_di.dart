import 'package:dartz/dartz.dart';
import 'package:mgmess/core/config/app_config.dart';
import 'package:mgmess/core/di/injection.dart';
import 'package:mgmess/core/di/server_session.dart';
import 'package:mgmess/core/di/session_manager.dart';
import 'package:mgmess/domain/entities/channel.dart';
import 'package:mgmess/domain/entities/server_account.dart';
import 'package:mgmess/domain/entities/channel_category.dart';
import 'package:mgmess/domain/entities/channel_member.dart';
import 'package:mgmess/domain/entities/channel_stats.dart';
import 'package:mgmess/domain/entities/user.dart';
import 'package:mgmess/core/network/api_client.dart';
import 'package:mgmess/core/network/network_info.dart';
import 'package:mgmess/core/network/websocket_client.dart';
import 'package:mgmess/core/notifications/notification_service.dart';
import 'package:mgmess/core/storage/secure_storage.dart';
import 'package:mgmess/data/datasources/remote/emoji_remote_datasource.dart';
import 'package:mgmess/data/services/ws_post_parser_impl.dart';
import 'package:mgmess/core/auth/biometric_service.dart';
import 'package:mgmess/core/feature_flags/feature_flags.dart';
import 'package:mgmess/core/observability/analytics_service.dart';
import 'package:mgmess/domain/repositories/server_account_repository.dart';
import 'package:mgmess/presentation/blocs/auth/auth_bloc.dart';
import 'package:mgmess/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:mgmess/presentation/blocs/notification/notification_bloc.dart';
import 'package:mgmess/presentation/blocs/locale/locale_cubit.dart';
import 'package:mgmess/presentation/blocs/server/server_list_cubit.dart';
import 'package:mgmess/presentation/blocs/theme/theme_cubit.dart';
import 'package:mgmess/presentation/blocs/user_status/user_status_cubit.dart';
import 'package:mgmess/presentation/blocs/websocket/websocket_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/fake_notification_service.dart';
import '../mocks/fake_secure_storage.dart';
import '../mocks/fake_websocket.dart';
import '../mocks/mock_repositories.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockEmojiRemoteDataSource extends Mock
    implements EmojiRemoteDataSource {}

/// Контейнер с доступом к мокам для настройки when() в тестах.
class TestMocks {
  final MockAuthRepository authRepository;
  final MockChannelRepository channelRepository;
  final MockPostRepository postRepository;
  final MockUserRepository userRepository;
  final MockFileRepository fileRepository;
  final MockSeensRepository seensRepository;
  final MockNotificationRepository notificationRepository;
  final FakeWebSocketClient webSocketClient;
  final FakeSecureStorage secureStorage;
  final FakeNotificationService notificationService;

  const TestMocks({
    required this.authRepository,
    required this.channelRepository,
    required this.postRepository,
    required this.userRepository,
    required this.fileRepository,
    required this.seensRepository,
    required this.notificationRepository,
    required this.webSocketClient,
    required this.secureStorage,
    required this.notificationService,
  });
}

/// Mock NetworkInfo, всегда онлайн.
class FakeNetworkInfo extends NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(true);
}

/// Инициализирует тестовые зависимости в GetIt.
/// Повторяет структуру из lib/core/di/injection.dart, но с моками.
Future<TestMocks> initTestDependencies() async {
  await sl.reset();

  AppConfig.serverUrlOverride = 'https://mm.my.games';
  SharedPreferences.setMockInitialValues({
    'onboarding_completed': true,
  });

  // Register fallback values for mocktail
  registerFallbackValue(ServerAccount(
    id: 'fallback',
    serverUrl: 'https://fallback',
    addedAt: DateTime(2020),
    lastActiveAt: DateTime(2020),
  ));

  // Создаём моки
  final authRepo = MockAuthRepository();
  final channelRepo = MockChannelRepository();
  final postRepo = MockPostRepository();
  final userRepo = MockUserRepository();
  final fileRepo = MockFileRepository();
  final seensRepo = MockSeensRepository();
  final notificationRepo = MockNotificationRepository();
  final serverAccountRepo = MockServerAccountRepository();
  final wsClient = FakeWebSocketClient();
  final secureStorage = FakeSecureStorage();
  final notificationService = FakeNotificationService();
  final networkInfo = FakeNetworkInfo();

  // Дефолтные стабы для UserRepository (нужен UserStatusCubit и DM каналы)
  // Возвращаем 'offline' для каждого запрошенного userId, чтобы UserStatusCubit
  // не пересоздавал таймер бесконечно (иначе pending timers ломают тесты).
  when(() => userRepo.getUserStatuses(any()))
      .thenAnswer((invocation) async {
    final ids = invocation.positionalArguments[0] as List<String>;
    return Right((
      statuses: {for (final id in ids) id: 'offline'},
      lastActivity: <String, int>{},
    ));
  });
  when(() => userRepo.getUserImageUrl(any()))
      .thenReturn('https://mm.my.games/api/v4/users/fake/image');
  when(() => userRepo.getUser(any())).thenAnswer((_) async => const Right(
        User(id: 'user-002', username: 'otheruser', firstName: 'Other', lastName: 'User'),
      ));
  when(() => userRepo.autocompleteUsers(any(), channelId: any(named: 'channelId')))
      .thenAnswer((_) async => const Right([]));
  when(() => userRepo.updateUserStatus(any(), any()))
      .thenAnswer((_) async => const Right(null));
  when(() => userRepo.updateCustomStatus(any(),
          emoji: any(named: 'emoji'), text: any(named: 'text')))
      .thenAnswer((_) async => const Right(null));
  when(() => userRepo.deleteCustomStatus(any()))
      .thenAnswer((_) async => const Right(null));
  when(() => userRepo.getUsersByIds(any()))
      .thenAnswer((_) async => const Right([
            User(
              id: 'user-002',
              username: 'otheruser',
              firstName: 'Other',
              lastName: 'User',
            ),
          ]));

  // Дефолтные стабы для ChannelRepository
  when(() => channelRepo.getChannelStats(any()))
      .thenAnswer((_) async => const Right(ChannelStats(channelId: 'ch1', memberCount: 5)));
  when(() => channelRepo.getChannelMembers(any(),
          page: any(named: 'page'), perPage: any(named: 'perPage')))
      .thenAnswer((_) async => const Right(<ChannelMember>[]));
  when(() => channelRepo.leaveChannel(any(), any()))
      .thenAnswer((_) async => const Right(null));
  when(() => channelRepo.autocompleteChannels(any(), any()))
      .thenAnswer((_) async => const Right(<Channel>[]));
  when(() => channelRepo.getChannelCategories(any(), any()))
      .thenAnswer((_) async => const Right(<ChannelCategory>[]));
  when(() => channelRepo.updateChannelCategory(any(), any(), any(), any()))
      .thenAnswer((_) async => const Right(null));
  when(() => channelRepo.canUserPost(any(), any(), channel: any(named: 'channel')))
      .thenAnswer((_) async => const Right(true));
  when(() => channelRepo.getReadOnlyChannelIds(any(), any(), any()))
      .thenAnswer((_) async => const <String>{});

  // Дефолтные стабы для NotificationRepository
  when(() => notificationRepo.registerDeviceToken(any()))
      .thenAnswer((_) async => const Right(null));
  when(() => notificationRepo.unregisterDevice())
      .thenAnswer((_) async => const Right(null));

  // Дефолтные стабы для FileRepository
  when(() => fileRepo.getFileUrl(any()))
      .thenReturn('https://mm.my.games/api/v4/files/fake');
  when(() => fileRepo.getThumbnailUrl(any()))
      .thenReturn('https://mm.my.games/api/v4/files/fake/thumbnail');
  when(() => fileRepo.getPreviewUrl(any()))
      .thenReturn('https://mm.my.games/api/v4/files/fake/preview');
  when(() => fileRepo.getChannelFiles(any(),
          page: any(named: 'page'), perPage: any(named: 'perPage')))
      .thenAnswer((_) async => const Right([]));

  // Дефолтные стабы для ServerAccountRepository
  final now = DateTime.now();
  final testAccount = ServerAccount(
    id: 'test-account',
    serverUrl: 'https://mm.my.games',
    displayName: 'Test Server',
    addedAt: now,
    lastActiveAt: now,
  );
  when(() => serverAccountRepo.getAll())
      .thenAnswer((_) async => [testAccount]);
  when(() => serverAccountRepo.getActive())
      .thenAnswer((_) async => testAccount);
  when(() => serverAccountRepo.setActive(any()))
      .thenAnswer((_) async {});
  when(() => serverAccountRepo.update(any()))
      .thenAnswer((_) async {});

  // BLoCs for the test session
  final authBloc = AuthBloc(authRepository: authRepo);
  final wsBloc = WebSocketBloc(webSocketClient: wsClient);
  final notifBloc = NotificationBloc(
    repository: notificationRepo,
    notificationService: notificationService,
  );
  final userStatusCubit = UserStatusCubit(userRepository: userRepo);

  // Create a test session with all mock dependencies
  final testSession = ServerSession.forTest(
    accountId: 'test-account',
    serverUrl: 'https://mm.my.games',
    baseUrl: 'https://mm.my.games/api/v4',
    oauthUrl: 'https://mm.my.games/oauth/gitlab/mobile_login?redirect_to=mmauth:///oauth/callback',
    secureStorage: secureStorage,
    apiClient: MockApiClient(),
    webSocketClient: wsClient,
    authRepository: authRepo,
    userRepository: userRepo,
    channelRepository: channelRepo,
    postRepository: postRepo,
    fileRepository: fileRepo,
    seensRepository: seensRepo,
    notificationRepository: notificationRepo,
    authBloc: authBloc,
    webSocketBloc: wsBloc,
    notificationBloc: notifBloc,
    userStatusCubit: userStatusCubit,
    wsPostParser: WsPostParserImpl(),
    emojiRemoteDataSource: MockEmojiRemoteDataSource(),
  );

  // Core
  sl.registerLazySingleton<SecureStorage>(() => secureStorage);
  sl.registerLazySingleton<WebSocketClient>(() => wsClient);
  sl.registerLazySingleton<NetworkInfo>(() => networkInfo);
  sl.registerLazySingleton<NotificationService>(() => notificationService);
  sl.registerLazySingleton(() => BiometricService());

  // Observability & Feature Flags
  final analyticsService = AnalyticsService();
  await analyticsService.init();
  sl.registerLazySingleton(() => analyticsService);
  final featureFlagService = FeatureFlagService();
  await featureFlagService.init();
  sl.registerLazySingleton(() => featureFlagService);

  // SessionManager with test session as active
  final sessionManager = SessionManager(
    secureStorage: secureStorage,
    networkInfo: networkInfo,
    notificationService: notificationService,
  );
  // Manually inject the test session via the internal map
  sessionManager.setTestSession(testSession);
  sl.registerLazySingleton(() => sessionManager);

  // ServerAccountRepository
  sl.registerLazySingleton<ServerAccountRepository>(() => serverAccountRepo);

  // Global BLoCs / Cubits
  sl.registerFactory(() => ConnectivityCubit(networkInfo: sl()));
  sl.registerLazySingleton(() => ThemeCubit());
  sl.registerLazySingleton(() => LocaleCubit());
  sl.registerLazySingleton(() => ServerListCubit(
        accountRepo: sl(),
        sessionManager: sl(),
      ));

  return TestMocks(
    authRepository: authRepo,
    channelRepository: channelRepo,
    postRepository: postRepo,
    userRepository: userRepo,
    fileRepository: fileRepo,
    seensRepository: seensRepo,
    notificationRepository: notificationRepo,
    webSocketClient: wsClient,
    secureStorage: secureStorage,
    notificationService: notificationService,
  );
}
