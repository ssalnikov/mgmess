import 'package:get_it/get_it.dart';

import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/channel_remote_datasource.dart';
import '../../data/datasources/remote/file_remote_datasource.dart';
import '../../data/datasources/remote/post_remote_datasource.dart';
import '../../data/datasources/remote/seens_remote_datasource.dart';
import '../../data/datasources/remote/user_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/channel_repository_impl.dart';
import '../../data/repositories/file_repository_impl.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../data/repositories/seens_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/repositories/seens_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/connectivity/connectivity_cubit.dart';
import '../../presentation/blocs/websocket/websocket_bloc.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../network/websocket_client.dart';
import '../storage/secure_storage.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton(() => SecureStorage());
  sl.registerLazySingleton(() => ApiClient(secureStorage: sl()));
  sl.registerLazySingleton(() => WebSocketClient(secureStorage: sl()));
  sl.registerLazySingleton(() => NetworkInfo());

  // Data Sources
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

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      secureStorage: sl(),
    ),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ChannelRepository>(
    () => ChannelRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<FileRepository>(
    () => FileRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SeensRepository>(
    () => SeensRepositoryImpl(remoteDataSource: sl()),
  );

  // BLoCs
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(
      () => WebSocketBloc(webSocketClient: sl()));
  sl.registerFactory(() => ConnectivityCubit(networkInfo: sl()));
}
