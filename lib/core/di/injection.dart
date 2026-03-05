import 'package:get_it/get_it.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/channel_local_datasource.dart';
import '../../data/datasources/local/daos/channel_dao.dart';
import '../../data/datasources/local/daos/post_dao.dart';
import '../../data/datasources/local/daos/user_dao.dart';
import '../../data/datasources/local/post_local_datasource.dart';
import '../../data/datasources/local/user_local_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/emoji_remote_datasource.dart';
import '../../data/datasources/remote/channel_remote_datasource.dart';
import '../../data/datasources/remote/file_remote_datasource.dart';
import '../../data/datasources/remote/notification_remote_datasource.dart';
import '../../data/datasources/remote/post_remote_datasource.dart';
import '../../data/datasources/remote/seens_remote_datasource.dart';
import '../../data/datasources/remote/user_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/send_queue_service.dart';
import '../../data/services/ws_post_parser_impl.dart';
import '../../data/repositories/channel_repository_impl.dart';
import '../../data/repositories/file_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../data/repositories/seens_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/repositories/seens_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/services/ws_post_parser.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/connectivity/connectivity_cubit.dart';
import '../../presentation/blocs/notification/notification_bloc.dart';
import '../../presentation/blocs/user_status/user_status_cubit.dart';
import '../../presentation/blocs/websocket/websocket_bloc.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../network/websocket_client.dart';
import '../notifications/notification_service.dart';
import '../storage/draft_storage.dart';
import '../storage/secure_storage.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton(() => SecureStorage());
  sl.registerLazySingleton(() => DraftStorage());
  sl.registerLazySingleton(() => ApiClient(secureStorage: sl()));
  sl.registerLazySingleton(() => WebSocketClient(secureStorage: sl()));
  sl.registerLazySingleton(() => NetworkInfo());
  sl.registerLazySingleton(() => NotificationService());

  // Database
  sl.registerLazySingleton(() => AppDatabase());

  // DAOs
  sl.registerLazySingleton(() => PostDao(sl<AppDatabase>()));
  sl.registerLazySingleton(() => ChannelDao(sl<AppDatabase>()));
  sl.registerLazySingleton(() => UserDao(sl<AppDatabase>()));

  // Local Data Sources
  sl.registerLazySingleton(
      () => PostLocalDataSource(dao: sl()));
  sl.registerLazySingleton(
      () => ChannelLocalDataSource(dao: sl()));
  sl.registerLazySingleton(
      () => UserLocalDataSource(dao: sl()));

  // Remote Data Sources
  sl.registerLazySingleton(
      () => AuthRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton(
      () => UserRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton(
      () => ChannelRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton(
      () => PostRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton(
      () => FileRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton(
      () => SeensRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton(
      () => NotificationRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton(
      () => EmojiRemoteDataSource(apiClient: sl()));

  // Services
  sl.registerLazySingleton<WsPostParser>(() => WsPostParserImpl());
  sl.registerLazySingleton(() => SendQueueService(
        localDataSource: sl(),
        remoteDataSource: sl(),
        networkInfo: sl(),
      ));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      secureStorage: sl(),
    ),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<ChannelRepository>(
    () => ChannelRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      userRemoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<FileRepository>(
    () => FileRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SeensRepository>(
    () => SeensRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );

  // BLoCs
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(
      () => WebSocketBloc(webSocketClient: sl()));
  sl.registerFactory(() => ConnectivityCubit(networkInfo: sl()));
  sl.registerFactory(() => NotificationBloc(
        repository: sl(),
        notificationService: sl(),
      ));
  sl.registerFactory(
      () => UserStatusCubit(userRepository: sl()));
}
