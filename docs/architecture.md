# Архитектура MGMess

## Обзор

Проект построен по принципам **Clean Architecture** с чётким разделением на три слоя: Domain, Data и Presentation. Зависимости направлены внутрь — внешние слои зависят от внутренних, но не наоборот.

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│   (BLoC, Screens, Widgets)              │
├─────────────────────────────────────────┤
│             Domain Layer                │
│   (Entities, Repositories, UseCases)    │
├─────────────────────────────────────────┤
│              Data Layer                 │
│   (Models, DataSources, Repositories)   │
├─────────────────────────────────────────┤
│              Core Layer                      │
│ (Network, Storage, DI, Router, Observability) │
└─────────────────────────────────────────┘
```

## Структура проекта

```
lib/
├── main.dart                              # Точка входа
├── app.dart                               # MaterialApp, провайдеры, роутинг
│
├── core/                                  # Инфраструктура (общая для всех слоёв)
│   ├── config/
│   │   └── app_config.dart                # URL сервера, таймауты, константы
│   ├── di/
│   │   └── injection.dart                 # GetIt — регистрация зависимостей
│   ├── error/
│   │   ├── failures.dart                  # Failure-классы (ServerFailure, AuthFailure, ...)
│   │   └── exceptions.dart                # Exception-классы
│   ├── network/
│   │   ├── api_client.dart                # Dio + AuthInterceptor + RetryInterceptor
│   │   ├── api_endpoints.dart             # Все REST-эндпоинты как константы
│   │   ├── websocket_client.dart          # WS-менеджер (connect/reconnect/subscribe)
│   │   ├── websocket_events.dart          # Типизированные WS-события
│   │   └── network_info.dart              # Мониторинг connectivity
│   ├── storage/
│   │   └── secure_storage.dart            # flutter_secure_storage (токены)
│   ├── router/
│   │   ├── app_router.dart                # GoRouter + auth guard + deep links
│   │   └── route_names.dart               # Именованные маршруты
│   ├── theme/
│   │   ├── app_theme.dart                 # Light/Dark темы
│   │   ├── app_colors.dart                # Палитра цветов
│   │   └── app_text_styles.dart           # Стили текста
│   ├── notifications/
│   │   ├── notification_service.dart      # FCM + flutter_local_notifications
│   │   └── notification_channels.dart     # Android notification channel IDs
│   ├── observability/
│   │   ├── crash_reporting.dart           # Sentry: крешы, breadcrumbs, user context
│   │   └── analytics_service.dart         # Трекинг событий (login, message_sent, etc.)
│   ├── feature_flags/
│   │   └── feature_flags.dart             # FeatureFlag enum + FeatureFlagService
│   └── utils/
│       └── date_formatter.dart            # Форматирование дат/времени
│
├── domain/                                # Бизнес-логика (без зависимостей от Flutter)
│   ├── entities/                          # Чистые бизнес-объекты
│   │   ├── user.dart
│   │   ├── team.dart
│   │   ├── channel.dart
│   │   ├── post.dart
│   │   ├── file_info.dart
│   │   └── seen_list.dart
│   ├── repositories/                      # Абстрактные контракты (интерфейсы)
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   ├── channel_repository.dart
│   │   ├── post_repository.dart
│   │   ├── file_repository.dart
│   │   ├── seens_repository.dart
│   │   └── notification_repository.dart
│   └── services/                          # Абстрактные сервисы
│       └── ws_post_parser.dart            # Интерфейс парсинга постов из WS-событий
│
├── data/                                  # Реализация доступа к данным
│   ├── datasources/
│   │   ├── remote/                        # Удалённые источники данных (REST API)
│   │   │   ├── auth_remote_datasource.dart
│   │   │   ├── user_remote_datasource.dart
│   │   │   ├── channel_remote_datasource.dart
│   │   │   ├── post_remote_datasource.dart
│   │   │   ├── file_remote_datasource.dart
│   │   │   ├── seens_remote_datasource.dart
│   │   │   └── notification_remote_datasource.dart
│   │   └── local/                         # Локальные источники данных (Drift/SQLite)
│   │       ├── app_database.dart          # Drift БД: таблицы Posts, Channels, Users
│   │       ├── app_database.g.dart        # Сгенерированный код Drift
│   │       ├── daos/                      # Data Access Objects
│   │       │   ├── post_dao.dart          # CRUD + pending posts + upsert batch
│   │       │   ├── channel_dao.dart       # CRUD + membership update
│   │       │   └── user_dao.dart          # CRUD + batch fetch by IDs
│   │       ├── mappers/                   # Entity <-> DB row маппинг
│   │       │   ├── post_mapper.dart       # PostModel ↔ PostsCompanion
│   │       │   ├── channel_mapper.dart    # ChannelModel ↔ ChannelsCompanion
│   │       │   └── user_mapper.dart       # UserModel ↔ UsersCompanion
│   │       ├── post_local_datasource.dart # Кеш постов, pending-очередь
│   │       ├── channel_local_datasource.dart # Кеш каналов
│   │       └── user_local_datasource.dart # Кеш пользователей
│   ├── models/                            # DTO — маппинг JSON <-> Entity
│   │   ├── user_model.dart
│   │   ├── channel_model.dart
│   │   ├── post_model.dart
│   │   ├── file_info_model.dart
│   │   └── seen_list_model.dart
│   ├── repositories/                      # Реализации контрактов из domain/
│   │   ├── auth_repository_impl.dart
│   │   ├── user_repository_impl.dart
│   │   ├── channel_repository_impl.dart
│   │   ├── post_repository_impl.dart
│   │   ├── file_repository_impl.dart
│   │   ├── seens_repository_impl.dart
│   │   └── notification_repository_impl.dart
│   └── services/                          # Реализации сервисов из domain/
│       ├── ws_post_parser_impl.dart       # Парсинг постов из WS JSON-строк
│       └── send_queue_service.dart        # Очередь отправки офлайн-сообщений
│
└── presentation/                          # UI и управление состоянием
    ├── blocs/                             # Глобальные BLoC/Cubit
    │   ├── auth/                          # AuthBloc — сессия, OAuth, logout
    │   ├── websocket/                     # WebSocketBloc — WS-подключение
    │   ├── connectivity/                  # ConnectivityCubit — состояние сети
    │   └── notification/                  # NotificationBloc — FCM, push-уведомления
    ├── screens/
    │   ├── auth/                          # Экран авторизации
    │   ├── channels/                      # Список каналов + ChannelsBloc
    │   ├── chat/                          # Чат + ChatBloc + виджеты сообщений
    │   │   └── widgets/
    │   │       ├── message_bubble.dart     # Сообщение (приоритеты, действия)
    │   │       ├── message_input.dart      # Ввод с приоритетами и @-автодополнением
    │   │       ├── mention_autocomplete.dart # UI автодополнения @упоминаний
    │   │       ├── message_actions_sheet.dart # Действия: цитата, пересылка, pin/unpin, удаление
    │   │       ├── channel_picker_sheet.dart # Выбор канала для пересылки
    │   │       ├── pinned_messages_bloc.dart # BLoC закреплённых сообщений
    │   │       └── pinned_messages_sheet.dart # Панель закреплённых сообщений
    │   ├── thread/                        # Тред + ThreadBloc
    │   ├── saved_messages/                # Сохранённые сообщения + SavedMessagesBloc
    │   ├── mentions/                      # Упоминания + MentionsBloc
    │   └── profile/                       # Профиль, настройки уведомлений
    ├── utils/
    │   └── forward_helper.dart            # Логика пересылки сообщений
    └── widgets/                           # Переиспользуемые виджеты
        ├── user_avatar.dart
        ├── bottom_nav_shell.dart
        ├── loading_indicator.dart
        ├── error_display.dart
        ├── file_icon.dart
        └── swipe_back_wrapper.dart        # Обёртка для навигации свайпом назад
```

## Слои

### Domain Layer

Ядро приложения. Не зависит от Flutter, Dio, или любых внешних пакетов. Содержит:

- **Entities** — неизменяемые бизнес-объекты (`User`, `Channel`, `Post`, `FileInfo`, `SeenList`). Наследуют `Equatable` для сравнения по значению. `Post` использует поле `priority` (urgent / important / пустая строка).
- **Repository contracts** — абстрактные классы, определяющие что можно делать с данными. Возвращают `Either<Failure, T>` (пакет `dartz`) для явной обработки ошибок без исключений.
- **Services** — абстрактные интерфейсы сервисов (`WsPostParser` — централизованный парсинг постов из WebSocket-событий).

### Data Layer

Реализация доступа к данным:

- **Models** — наследники Entity с методами `fromJson`/`toJson`. Отвечают за сериализацию. `PostModel` парсит приоритет из `metadata.priority.priority`.
- **Remote DataSources** — классы, работающие с REST API через `ApiClient` (Dio). Бросают `ServerException` при ошибках. `UserRemoteDataSource` включает `autocompleteUsers` для @-автодополнения.
- **Local DataSources** — классы, работающие с локальной БД Drift (SQLite). Бросают `CacheException` при ошибках. Обеспечивают офлайн-доступ к данным и кеширование. Каждый DataSource использует соответствующий DAO и Mapper.
- **Repository Implementations** — реализуют контракты из Domain. Трёхуровневая стратегия: онлайн → сеть + фоновый кеш; офлайн → локальный кеш; ошибка сервера → fallback на кеш. `PostRepositoryImpl` и `ChannelRepositoryImpl` используют `NetworkInfo` для выбора источника данных. `UserRepositoryImpl` применяет стратегию cache-first (сначала локальный кеш, потом API).
- **Services** — реализации сервисов из Domain: `WsPostParserImpl` (парсинг `data.post` JSON-строк из WS-событий), `SendQueueService` (очередь офлайн-сообщений — при восстановлении сети отправляет pending-посты).

#### Локальная БД (Drift/SQLite)

`AppDatabase` (`data/datasources/local/app_database.dart`) — Drift-база с тремя таблицами:

| Таблица | Назначение | Ключевые поля |
|---------|------------|---------------|
| `Posts` | Кеш сообщений + офлайн-очередь | `isPending`, `sendStatus` (0=ok, 1=pending, 2=failed) |
| `Channels` | Кеш каналов с membership-данными | `msgCount`, `mentionCount`, `lastViewedAt`, `isMuted` |
| `Users` | Кеш пользователей | `status` |

JSON-поля (`metadataJson`, `fileIdsJson`, `filesJson`, `reactionsJson`) хранятся как TEXT и десериализуются в Mapper-ах.

Файл БД: `<documents>/mgmess.db` (создаётся через `NativeDatabase.createInBackground`).

#### SendQueueService

Сервис для отправки сообщений, созданных офлайн:
1. Подписывается на `NetworkInfo.onConnectivityChanged`
2. При восстановлении сети забирает pending-посты из `PostLocalDataSource.getPendingPosts()`
3. Отправляет каждый через `PostRemoteDataSource.createPost()`
4. Успех → `markAsSent()`, ошибка → `markAsFailed()`

### Presentation Layer

- **BLoC** (Business Logic Component) — управление состоянием через паттерн Event → BLoC → State. Подробнее см. [State Management](state_management.md).
- **Screens** — полноэкранные виджеты, каждый со своим BLoC.
- **Widgets** — переиспользуемые UI-компоненты.

### Core Layer

Общая инфраструктура:

- **ApiClient** — Dio HTTP-клиент с тремя interceptors (auth, retry, logging + Sentry breadcrumbs)
- **WebSocketClient** — управление WS-соединением с автоматическим reconnect
- **SecureStorage** — безопасное хранение токенов (Keychain на iOS, EncryptedSharedPreferences на Android)
- **AppRouter** — GoRouter с auth guard (автоматический редирект на экран авторизации)
- **DI** — GetIt Service Locator для внедрения зависимостей
- **CrashReporting** — Sentry SDK для перехвата крешей, breadcrumbs, user context. См. [Observability](observability.md)
- **AnalyticsService** — легковесный трекинг событий (login, message_sent, search и др.) с хранением в SharedPreferences. См. [Observability](observability.md)
- **FeatureFlagService** — флаги функций с 3-уровневым разрешением (local override → remote config → default). См. [Feature Flags](feature_flags.md)

## Dependency Injection

Регистрация зависимостей выполняется в `core/di/injection.dart` при запуске приложения:

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();  // Регистрация всех зависимостей в GetIt
  runApp(const App());
}
```

Порядок регистрации:
1. Core-сервисы (SecureStorage, DraftStorage, ApiClient, WebSocketClient, NetworkInfo, NotificationService, BiometricService, **AnalyticsService**, **FeatureFlagService**)
2. Database (AppDatabase)
3. DAOs (PostDao, ChannelDao, UserDao, ChannelCategoryDao)
4. Local DataSources (PostLocalDataSource, ChannelLocalDataSource, UserLocalDataSource, ChannelCategoryLocalDataSource)
5. Remote DataSources (все remote data sources)
6. Services (WsPostParser → WsPostParserImpl, SendQueueService)
7. Repositories (реализации, зарегистрированные по абстрактным типам)
8. BLoCs (AuthBloc, WebSocketBloc, ConnectivityCubit, NotificationBloc, UserStatusCubit, ThemeCubit, LocaleCubit)

Доступ к зависимостям: `sl<AuthRepository>()` (где `sl` — глобальный экземпляр GetIt).

## Навигация

Используется **GoRouter** с декларативным описанием маршрутов:

| Маршрут | Экран | Описание |
|---------|-------|----------|
| `/auth` | AuthScreen | Авторизация через GitLab |
| `/channels` | ChannelsScreen | Список каналов (в ShellRoute с bottom nav) |
| `/saved` | SavedMessagesScreen | Сохранённые сообщения |
| `/mentions` | MentionsScreen | Упоминания |
| `/profile` | ProfileScreen | Профиль текущего пользователя |
| `/chat/:channelId` | ChatScreen | Чат в канале (extra: dmUserId, scrollToPostId) |
| `/profile/edit` | EditProfileScreen | Редактирование профиля |
| `/profile/notifications` | NotificationSettingsScreen | Настройки push-уведомлений |
| `/user/:userId` | UserProfileScreen | Просмотр профиля другого пользователя |

**Auth guard**: если пользователь не авторизован — любой маршрут редиректит на `/auth`. При авторизации — `/auth` редиректит на `/channels`.

## Ключевые пакеты

| Пакет | Назначение |
|-------|------------|
| `flutter_bloc` | State management (BLoC + Cubit) |
| `dio` | HTTP-клиент с interceptors |
| `web_socket_channel` | WebSocket-соединение |
| `get_it` | Dependency Injection (Service Locator) |
| `go_router` | Декларативная навигация + deep links |
| `app_links` | Перехват deep links (OAuth callback) |
| `flutter_secure_storage` | Безопасное хранение токенов |
| `dartz` | Функциональное программирование (`Either<L, R>`) |
| `equatable` | Сравнение объектов по значению |
| `cached_network_image` | Кеширование изображений из сети |
| `flutter_markdown` | Рендеринг Markdown-сообщений |
| `photo_view` | Полноэкранный просмотр изображений |
| `image_picker` / `file_picker` | Выбор файлов для отправки |
| `drift` + `sqlite3_flutter_libs` | Локальная БД (SQLite) для офлайн-кеша |
| `path_provider` | Путь к директории документов (для файла БД) |
| `connectivity_plus` | Мониторинг состояния сети |
| `firebase_core` | Инициализация Firebase |
| `firebase_messaging` | Firebase Cloud Messaging (push-уведомления) |
| `flutter_local_notifications` | Локальные уведомления (foreground) |
| `app_badge_plus` | Бейдж на иконке приложения |
| `sentry_flutter` | Crash reporting + performance monitoring (Sentry) |
| `logger` | Структурированное логирование |
| `local_auth` | Биометрическая аутентификация (Face ID / Touch ID) |
