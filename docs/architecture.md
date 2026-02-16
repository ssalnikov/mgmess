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
│              Core Layer                 │
│   (Network, Storage, DI, Router, Theme) │
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
│   └── repositories/                      # Абстрактные контракты (интерфейсы)
│       ├── auth_repository.dart
│       ├── user_repository.dart
│       ├── channel_repository.dart
│       ├── post_repository.dart
│       ├── file_repository.dart
│       ├── seens_repository.dart
│       └── notification_repository.dart
│
├── data/                                  # Реализация доступа к данным
│   ├── datasources/remote/                # Удалённые источники данных (REST API)
│   │   ├── auth_remote_datasource.dart
│   │   ├── user_remote_datasource.dart
│   │   ├── channel_remote_datasource.dart
│   │   ├── post_remote_datasource.dart
│   │   ├── file_remote_datasource.dart
│   │   ├── seens_remote_datasource.dart
│   │   └── notification_remote_datasource.dart
│   ├── models/                            # DTO — маппинг JSON <-> Entity
│   │   ├── user_model.dart
│   │   ├── channel_model.dart
│   │   ├── post_model.dart
│   │   ├── file_info_model.dart
│   │   └── seen_list_model.dart
│   └── repositories/                      # Реализации контрактов из domain/
│       ├── auth_repository_impl.dart
│       ├── user_repository_impl.dart
│       ├── channel_repository_impl.dart
│       ├── post_repository_impl.dart
│       ├── file_repository_impl.dart
│       ├── seens_repository_impl.dart
│       └── notification_repository_impl.dart
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
    │   ├── saved_messages/                # Сохранённые сообщения + SavedMessagesBloc
    │   ├── mentions/                      # Упоминания + MentionsBloc
    │   └── profile/                       # Профиль, настройки уведомлений
    └── widgets/                           # Переиспользуемые виджеты
        ├── user_avatar.dart
        ├── bottom_nav_shell.dart
        ├── loading_indicator.dart
        ├── error_display.dart
        └── file_icon.dart
```

## Слои

### Domain Layer

Ядро приложения. Не зависит от Flutter, Dio, или любых внешних пакетов. Содержит:

- **Entities** — неизменяемые бизнес-объекты (`User`, `Channel`, `Post`, `FileInfo`, `SeenList`). Наследуют `Equatable` для сравнения по значению.
- **Repository contracts** — абстрактные классы, определяющие что можно делать с данными. Возвращают `Either<Failure, T>` (пакет `dartz`) для явной обработки ошибок без исключений.

### Data Layer

Реализация доступа к данным:

- **Models** — наследники Entity с методами `fromJson`/`toJson`. Отвечают за сериализацию.
- **DataSources** — классы, непосредственно работающие с REST API через `ApiClient` (Dio). Бросают `ServerException` при ошибках.
- **Repository Implementations** — реализуют контракты из Domain. Оборачивают исключения от DataSource в `Failure`-объекты. Содержат in-memory кеш (например, `UserRepositoryImpl`).

### Presentation Layer

- **BLoC** (Business Logic Component) — управление состоянием через паттерн Event → BLoC → State. Подробнее см. [State Management](state_management.md).
- **Screens** — полноэкранные виджеты, каждый со своим BLoC.
- **Widgets** — переиспользуемые UI-компоненты.

### Core Layer

Общая инфраструктура:

- **ApiClient** — Dio HTTP-клиент с тремя interceptors (auth, retry, logging)
- **WebSocketClient** — управление WS-соединением с автоматическим reconnect
- **SecureStorage** — безопасное хранение токенов (Keychain на iOS, EncryptedSharedPreferences на Android)
- **AppRouter** — GoRouter с auth guard (автоматический редирект на экран авторизации)
- **DI** — GetIt Service Locator для внедрения зависимостей

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
1. Core-сервисы (SecureStorage, ApiClient, WebSocketClient, NetworkInfo, NotificationService)
2. DataSources (все remote data sources)
3. Repositories (реализации, зарегистрированные по абстрактным типам)
4. BLoCs (AuthBloc, WebSocketBloc, ConnectivityCubit, NotificationBloc)

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
| `/chat/:channelId` | ChatScreen | Чат в канале |
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
| `connectivity_plus` | Мониторинг состояния сети |
| `firebase_core` | Инициализация Firebase |
| `firebase_messaging` | Firebase Cloud Messaging (push-уведомления) |
| `flutter_local_notifications` | Локальные уведомления (foreground) |
| `flutter_app_badger` | Бейдж на иконке приложения |
| `logger` | Структурированное логирование |
