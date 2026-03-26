import 'package:get_it/get_it.dart';

import '../../data/repositories/server_account_repository_impl.dart';
import '../../domain/repositories/server_account_repository.dart';
import '../../presentation/blocs/connectivity/connectivity_cubit.dart';
import '../../presentation/blocs/locale/locale_cubit.dart';
import '../../presentation/blocs/server/server_list_cubit.dart';
import '../../presentation/blocs/theme/theme_cubit.dart';
import '../auth/biometric_service.dart';
import '../feature_flags/feature_flags.dart';
import '../network/network_info.dart';
import '../notifications/notification_service.dart';
import '../observability/analytics_service.dart';
import '../storage/secure_storage.dart';
import 'server_session.dart';
import 'session_manager.dart';

final sl = GetIt.instance;

/// Convenience accessor for the active [ServerSession].
///
/// Use in `initState`, field initializers, and other code paths where
/// `BuildContext` is not available. In `build` methods, prefer
/// `context.serverSession` from [ServerSessionProvider].
ServerSession get currentSession => sl<SessionManager>().activeSession!;

Future<void> initDependencies() async {
  // ── Global singletons (shared across all servers) ──

  sl.registerLazySingleton(() => SecureStorage());
  sl.registerLazySingleton<ServerAccountRepository>(
    () => ServerAccountRepositoryImpl(),
  );
  sl.registerLazySingleton(() => NetworkInfo());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => BiometricService());
  sl.registerLazySingleton(() => AnalyticsService());
  sl.registerLazySingleton(() => FeatureFlagService());

  // SessionManager
  sl.registerLazySingleton(() => SessionManager(
        secureStorage: sl(),
        networkInfo: sl(),
        notificationService: sl(),
      ));

  // Global BLoCs / Cubits
  sl.registerFactory(() => ConnectivityCubit(networkInfo: sl()));
  sl.registerLazySingleton(() => ThemeCubit());
  sl.registerLazySingleton(() => LocaleCubit());
  sl.registerLazySingleton(() => ServerListCubit(
        accountRepo: sl(),
        sessionManager: sl(),
      ));
}
