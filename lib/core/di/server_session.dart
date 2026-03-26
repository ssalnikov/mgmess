import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/channel_category_local_datasource.dart';
import '../../data/datasources/local/channel_local_datasource.dart';
import '../../data/datasources/local/daos/channel_category_dao.dart';
import '../../data/datasources/local/daos/channel_dao.dart';
import '../../data/datasources/local/daos/post_dao.dart';
import '../../data/datasources/local/daos/user_dao.dart';
import '../../data/datasources/local/post_local_datasource.dart';
import '../../data/datasources/local/user_local_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/channel_remote_datasource.dart';
import '../../data/datasources/remote/command_remote_datasource.dart';
import '../../data/datasources/remote/emoji_remote_datasource.dart';
import '../../data/datasources/remote/file_remote_datasource.dart';
import '../../data/datasources/remote/notification_remote_datasource.dart';
import '../../data/datasources/remote/post_remote_datasource.dart';
import '../../data/datasources/remote/seens_remote_datasource.dart';
import '../../data/datasources/remote/user_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/channel_repository_impl.dart';
import '../../data/repositories/file_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../data/repositories/seens_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/services/send_queue_service.dart';
import '../../data/services/ws_post_parser_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/repositories/seens_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/services/ws_post_parser.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/notification/notification_bloc.dart';
import '../../presentation/blocs/user_status/user_status_cubit.dart';
import '../../presentation/blocs/websocket/websocket_bloc.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../network/websocket_client.dart';
import '../notifications/notification_service.dart';
import '../storage/draft_storage.dart';
import '../storage/secure_storage.dart';

/// Per-server dependency container.
///
/// Holds a full set of network, database, data source, repository, service,
/// and BLoC instances scoped to a single Mattermost server account.
class ServerSession {
  final String accountId;
  final String serverUrl;
  final String displayName;
  final SecureStorage _secureStorage;

  /// API base URL for this server (e.g. `https://mm.my.games/api/v4`).
  late final String baseUrl;

  /// Full OAuth URL for this server.
  late final String oauthUrl;

  // --- Network ---
  late final ApiClient apiClient;
  late final WebSocketClient webSocketClient;

  // --- Database ---
  late final AppDatabase database;

  // --- DAOs ---
  late final PostDao postDao;
  late final ChannelDao channelDao;
  late final UserDao userDao;
  late final ChannelCategoryDao channelCategoryDao;

  // --- Local Data Sources ---
  late final PostLocalDataSource postLocalDataSource;
  late final ChannelLocalDataSource channelLocalDataSource;
  late final UserLocalDataSource userLocalDataSource;
  late final ChannelCategoryLocalDataSource channelCategoryLocalDataSource;

  // --- Remote Data Sources ---
  late final AuthRemoteDataSource authRemoteDataSource;
  late final UserRemoteDataSource userRemoteDataSource;
  late final ChannelRemoteDataSource channelRemoteDataSource;
  late final PostRemoteDataSource postRemoteDataSource;
  late final FileRemoteDataSource fileRemoteDataSource;
  late final SeensRemoteDataSource seensRemoteDataSource;
  late final NotificationRemoteDataSource notificationRemoteDataSource;
  late final EmojiRemoteDataSource emojiRemoteDataSource;
  late final CommandRemoteDataSource commandRemoteDataSource;

  // --- Storage ---
  late final DraftStorage draftStorage;

  // --- Services ---
  late final WsPostParser wsPostParser;
  late final SendQueueService sendQueueService;

  // --- Repositories ---
  late final AuthRepository authRepository;
  late final UserRepository userRepository;
  late final ChannelRepository channelRepository;
  late final PostRepository postRepository;
  late final FileRepository fileRepository;
  late final SeensRepository seensRepository;
  late final NotificationRepository notificationRepository;

  // --- BLoCs (per-server globals) ---
  late final AuthBloc authBloc;
  late final WebSocketBloc webSocketBloc;
  late final NotificationBloc notificationBloc;
  late final UserStatusCubit userStatusCubit;

  ServerSession({
    required this.accountId,
    required this.serverUrl,
    this.displayName = '',
    required SecureStorage secureStorage,
    required NetworkInfo networkInfo,
    required NotificationService notificationService,
  }) : _secureStorage = secureStorage {
    baseUrl = '$serverUrl${AppConfig.apiV4}';
    oauthUrl =
        '$serverUrl${AppConfig.oauthPath}?redirect_to=${AppConfig.callbackScheme}://${AppConfig.callbackPath}';
    final wsUrl = _buildWsUrl(serverUrl);

    // Network
    apiClient = ApiClient(
      secureStorage: secureStorage,
      baseUrl: baseUrl,
      accountId: accountId,
    );
    webSocketClient = WebSocketClient(
      secureStorage: secureStorage,
      wsUrl: wsUrl,
      accountId: accountId,
    );

    // Database
    database = AppDatabase.named('mgmess_$accountId.db');

    // DAOs
    postDao = PostDao(database);
    channelDao = ChannelDao(database);
    userDao = UserDao(database);
    channelCategoryDao = ChannelCategoryDao(database);

    // Local Data Sources
    postLocalDataSource = PostLocalDataSource(dao: postDao);
    channelLocalDataSource = ChannelLocalDataSource(dao: channelDao);
    userLocalDataSource = UserLocalDataSource(dao: userDao);
    channelCategoryLocalDataSource =
        ChannelCategoryLocalDataSource(dao: channelCategoryDao);

    // Remote Data Sources
    authRemoteDataSource = AuthRemoteDataSource(apiClient: apiClient);
    userRemoteDataSource = UserRemoteDataSource(apiClient: apiClient);
    channelRemoteDataSource = ChannelRemoteDataSource(apiClient: apiClient);
    postRemoteDataSource = PostRemoteDataSource(apiClient: apiClient);
    fileRemoteDataSource = FileRemoteDataSource(apiClient: apiClient);
    seensRemoteDataSource = SeensRemoteDataSource(apiClient: apiClient);
    notificationRemoteDataSource =
        NotificationRemoteDataSource(apiClient: apiClient);
    emojiRemoteDataSource = EmojiRemoteDataSource(apiClient: apiClient);
    commandRemoteDataSource = CommandRemoteDataSource(apiClient: apiClient);

    // Storage
    draftStorage = DraftStorage(accountId: accountId);

    // Services
    wsPostParser = WsPostParserImpl();
    sendQueueService = SendQueueService(
      localDataSource: postLocalDataSource,
      remoteDataSource: postRemoteDataSource,
      networkInfo: networkInfo,
    );

    // Repositories
    authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
      secureStorage: secureStorage,
      accountId: accountId,
    );
    userRepository = UserRepositoryImpl(
      remoteDataSource: userRemoteDataSource,
      localDataSource: userLocalDataSource,
      baseUrl: baseUrl,
    );
    channelRepository = ChannelRepositoryImpl(
      remoteDataSource: channelRemoteDataSource,
      localDataSource: channelLocalDataSource,
      categoryLocalDataSource: channelCategoryLocalDataSource,
      networkInfo: networkInfo,
      userRemoteDataSource: userRemoteDataSource,
    );
    postRepository = PostRepositoryImpl(
      remoteDataSource: postRemoteDataSource,
      localDataSource: postLocalDataSource,
      commandDataSource: commandRemoteDataSource,
      networkInfo: networkInfo,
    );
    fileRepository = FileRepositoryImpl(
      remoteDataSource: fileRemoteDataSource,
      baseUrl: baseUrl,
    );
    seensRepository = SeensRepositoryImpl(
      remoteDataSource: seensRemoteDataSource,
    );
    notificationRepository = NotificationRepositoryImpl(
      remoteDataSource: notificationRemoteDataSource,
    );

    // BLoCs
    authBloc = AuthBloc(
      authRepository: authRepository,
      accountId: accountId,
    );
    webSocketBloc = WebSocketBloc(webSocketClient: webSocketClient);
    notificationBloc = NotificationBloc(
      repository: notificationRepository,
      notificationService: notificationService,
      accountId: accountId,
      serverDisplayName: displayName,
    );
    userStatusCubit = UserStatusCubit(userRepository: userRepository);
  }

  /// Test-only constructor that accepts all dependencies externally.
  @visibleForTesting
  ServerSession.forTest({
    required this.accountId,
    required this.serverUrl,
    this.displayName = '',
    required this.baseUrl,
    required this.oauthUrl,
    required SecureStorage secureStorage,
    required this.apiClient,
    required this.webSocketClient,
    required this.authRepository,
    required this.userRepository,
    required this.channelRepository,
    required this.postRepository,
    required this.fileRepository,
    required this.seensRepository,
    required this.notificationRepository,
    required this.authBloc,
    required this.webSocketBloc,
    required this.notificationBloc,
    required this.userStatusCubit,
    required this.wsPostParser,
    required this.emojiRemoteDataSource,
  }) : _secureStorage = secureStorage {
    draftStorage = DraftStorage(accountId: accountId);
  }

  /// Returns the auth token for this server account.
  Future<String?> getAuthToken() => _secureStorage.getAccountToken(accountId);

  Future<void> dispose() async {
    authBloc.close();
    webSocketBloc.close();
    notificationBloc.close();
    userStatusCubit.close();
    webSocketClient.dispose();
    await database.close();
  }

  static String _buildWsUrl(String serverUrl) {
    final uri = Uri.parse(serverUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$port${AppConfig.wsPath}';
  }
}
