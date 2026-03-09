import 'package:dartz/dartz.dart';
import 'package:mgmess/core/config/app_config.dart';
import 'package:mgmess/core/di/injection.dart';
import 'package:mgmess/domain/entities/channel.dart';
import 'package:mgmess/domain/entities/channel_category.dart';
import 'package:mgmess/domain/entities/channel_member.dart';
import 'package:mgmess/domain/entities/channel_stats.dart';
import 'package:mgmess/domain/entities/user.dart';
import 'package:mgmess/core/network/network_info.dart';
import 'package:mgmess/core/network/websocket_client.dart';
import 'package:mgmess/core/notifications/notification_service.dart';
import 'package:mgmess/core/storage/draft_storage.dart';
import 'package:mgmess/core/storage/secure_storage.dart';
import 'package:mgmess/domain/repositories/auth_repository.dart';
import 'package:mgmess/domain/repositories/channel_repository.dart';
import 'package:mgmess/domain/repositories/file_repository.dart';
import 'package:mgmess/domain/repositories/notification_repository.dart';
import 'package:mgmess/domain/repositories/post_repository.dart';
import 'package:mgmess/domain/repositories/seens_repository.dart';
import 'package:mgmess/domain/repositories/user_repository.dart';
import 'package:mgmess/domain/services/ws_post_parser.dart';
import 'package:mgmess/data/services/ws_post_parser_impl.dart';
import 'package:mgmess/core/auth/biometric_service.dart';
import 'package:mgmess/presentation/blocs/auth/auth_bloc.dart';
import 'package:mgmess/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:mgmess/presentation/blocs/notification/notification_bloc.dart';
import 'package:mgmess/presentation/blocs/locale/locale_cubit.dart';
import 'package:mgmess/presentation/blocs/theme/theme_cubit.dart';
import 'package:mgmess/presentation/blocs/user_status/user_status_cubit.dart';
import 'package:mgmess/presentation/blocs/websocket/websocket_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/fake_notification_service.dart';
import '../mocks/fake_secure_storage.dart';
import '../mocks/fake_websocket.dart';
import '../mocks/mock_repositories.dart';

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

  // Создаём моки
  final authRepo = MockAuthRepository();
  final channelRepo = MockChannelRepository();
  final postRepo = MockPostRepository();
  final userRepo = MockUserRepository();
  final fileRepo = MockFileRepository();
  final seensRepo = MockSeensRepository();
  final notificationRepo = MockNotificationRepository();
  final wsClient = FakeWebSocketClient();
  final secureStorage = FakeSecureStorage();
  final notificationService = FakeNotificationService();
  final networkInfo = FakeNetworkInfo();

  // Дефолтные стабы для UserRepository (нужен UserStatusCubit и DM каналы)
  when(() => userRepo.getUserStatuses(any()))
      .thenAnswer((_) async => const Right((
            statuses: <String, String>{},
            lastActivity: <String, int>{},
          )));
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

  // Core
  sl.registerLazySingleton<SecureStorage>(() => secureStorage);
  sl.registerLazySingleton(() => DraftStorage());
  sl.registerLazySingleton<WebSocketClient>(() => wsClient);
  sl.registerLazySingleton<NetworkInfo>(() => networkInfo);
  sl.registerLazySingleton<NotificationService>(() => notificationService);
  sl.registerLazySingleton(() => BiometricService());

  // Services
  sl.registerLazySingleton<WsPostParser>(() => WsPostParserImpl());

  // Repositories (мокированные по абстрактному типу)
  sl.registerLazySingleton<AuthRepository>(() => authRepo);
  sl.registerLazySingleton<UserRepository>(() => userRepo);
  sl.registerLazySingleton<ChannelRepository>(() => channelRepo);
  sl.registerLazySingleton<PostRepository>(() => postRepo);
  sl.registerLazySingleton<FileRepository>(() => fileRepo);
  sl.registerLazySingleton<SeensRepository>(() => seensRepo);
  sl.registerLazySingleton<NotificationRepository>(() => notificationRepo);

  // BLoCs (Factory — каждый раз новый)
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => WebSocketBloc(webSocketClient: sl()));
  sl.registerFactory(() => ConnectivityCubit(networkInfo: sl()));
  sl.registerFactory(
      () => NotificationBloc(repository: sl(), notificationService: sl()));
  sl.registerFactory(() => UserStatusCubit(userRepository: sl()));
  sl.registerLazySingleton(() => ThemeCubit());
  sl.registerLazySingleton(() => LocaleCubit());

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
