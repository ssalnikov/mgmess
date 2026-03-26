# План: поддержка нескольких серверов в MGMess

## Обзор

Добавить возможность подключаться к нескольким Mattermost-серверам одновременно и переключаться между ними. Модель: все серверы поддерживают WebSocket-соединения параллельно (для уведомлений и бейджей), но основной UI показывает данные активного сервера.

---

## Фаза 1: ServerAccount и реестр серверов — DONE

**Цель:** ввести модель данных для нескольких серверов и миграцию существующей единственной сессии.

**Что сделано:**

- `lib/domain/entities/server_account.dart` — Equatable-сущность (id, serverUrl, displayName, userId, username, addedAt, lastActiveAt) с fromJson/toJson/copyWith
- `lib/domain/repositories/server_account_repository.dart` — абстрактный интерфейс (getAll, getActive, add, remove, setActive, update)
- `lib/data/repositories/server_account_repository_impl.dart` — реализация на SharedPreferences (ключи `server_accounts`, `active_server_id`)
- `lib/core/storage/secure_storage.dart` — добавлены per-account методы (`saveAccountToken`, `getAccountToken`, `saveAccountCsrfToken`, `getAccountCsrfToken`, `saveAccountUserId`, `getAccountUserId`, `clearAccount`), плюс `hasLegacyToken` и `migrateLegacyToAccount`; legacy-методы сохранены для обратной совместимости
- `lib/core/storage/server_account_migration.dart` — `ServerAccountMigration.migrateIfNeeded()`: при первом запуске создаёт `ServerAccount` из legacy-токенов, переносит ключи в per-account формат, идемпотентна
- `lib/core/di/injection.dart` — зарегистрирован `ServerAccountRepository`
- `lib/main.dart` — вызов миграции при запуске
- `integration_test/mocks/fake_secure_storage.dart` — обновлён для per-account методов

**Тесты (30):**
- `test/models/server_account_test.dart` — serialization, copyWith, equality (7 тестов)
- `test/repositories/server_account_repository_test.dart` — CRUD, active switching (9 тестов)
- `test/storage/secure_storage_test.dart` — per-account isolation, migration (10 тестов)
- `test/storage/server_account_migration_test.dart` — миграция, идемпотентность, edge cases (4 теста)

---

## Фаза 2: ServerSession — изолированный контейнер зависимостей — DONE

**Цель:** заменить глобальные синглтоны на per-server контейнеры с обратной совместимостью.

**Что сделано:**

- `lib/core/network/api_client.dart` — добавлены опциональные параметры `baseUrl` и `accountId`; `_AuthInterceptor` использует per-account токены (`getAccountToken`/`getAccountCsrfToken`/`clearAccount`) при наличии accountId, иначе legacy-методы
- `lib/core/network/websocket_client.dart` — добавлены опциональные параметры `wsUrl` и `accountId`; per-account токен при подключении
- `lib/data/datasources/local/app_database.dart` — добавлен `AppDatabase.named(dbFileName)` для per-server БД; `_openConnection` параметризован по имени файла; дефолтный конструктор использует `mgmess.db`
- `lib/core/di/server_session.dart` — контейнер per-server зависимостей:
  - Сеть: `ApiClient` (baseUrl = `{serverUrl}/api/v4`), `WebSocketClient` (wsUrl = `wss://{host}/api/v4/websocket`)
  - БД: `AppDatabase.named('mgmess_{accountId}.db')` + 4 DAO
  - 4 Local DataSources, 9 Remote DataSources
  - 2 Services (`WsPostParser`, `SendQueueService`)
  - 7 Repositories (Auth, User, Channel, Post, File, Seens, Notification)
  - 4 BLoCs (AuthBloc, WebSocketBloc, NotificationBloc, UserStatusCubit)
  - `dispose()` закрывает BLoC-и, WS, БД
- `lib/core/di/session_manager.dart` — управление сессиями:
  - `createSession(account)` — создаёт `ServerSession`, кеширует по accountId
  - `switchTo(accountId)` — переключает активную сессию
  - `removeSession(accountId)` — dispose + удаление; если удалён активный, переключение на первый оставшийся
  - `dispose()` — dispose всех сессий
- `lib/core/di/injection.dart` — переписан:
  - Глобальные синглтоны: `SecureStorage`, `ServerAccountRepository`, `DraftStorage`, `NetworkInfo`, `NotificationService`, `BiometricService`, `AnalyticsService`, `FeatureFlagService`, `SessionManager`, `ConnectivityCubit`, `ThemeCubit`, `LocaleCubit`
  - Proxy-фабрики для обратной совместимости: `sl<ApiClient>()`, `sl<PostRepository>()`, `sl<AuthBloc>()` и др. делегируют к `SessionManager.activeSession` — все ~50 мест в экранах, использующих `sl<>()`, продолжают работать
- `lib/main.dart` — после миграции вызывает `_initActiveSession()`: получает активный аккаунт из `ServerAccountRepository`, создаёт сессию через `SessionManager`, активирует

**Тесты (18):**
- `test/core/server_session_test.dart` — создание зависимостей, baseUrl, изоляция сессий (4 теста)
- `test/core/session_manager_test.dart` — lifecycle, switching, dispose (8 тестов)
- `test/network/api_client_per_account_test.dart` — per-account токены, clearAccount на 401, legacy fallback (6 тестов)

**Итого после фаз 1+2:** 469 тестов, 0 ошибок.

---

## Фаза 3: Перестройка дерева виджетов и BLoC-провайдеров — DONE

**Цель:** UI показывает данные активного сервера, при переключении дерево перестраивается.

**Что сделано:**

- `lib/presentation/widgets/server_session_provider.dart` — InheritedWidget, предоставляет `ServerSession` вниз по дереву; `ServerSessionProvider.of(context)` + extension `context.serverSession`
- `lib/app.dart` — кардинально переделан: двухуровневая структура `MultiBlocProvider(Theme+Locale) → ServerSessionProvider(session) → MultiBlocProvider(per-server BLoCs) → MaterialApp.router`; `ValueKey(session.accountId)` для перестройки при смене сессии; `_session` берётся из `SessionManager.activeSession`
- `lib/core/config/app_config.dart` — удалены computed properties `baseUrl`, `wsUrl`, `oauthUrl` (теперь вычисляются в `ServerSession`); оставлены `serverUrl`, `isServerConfigured`, константы путей (`apiV4`, `wsPath`, `oauthPath`, `callbackScheme`, `callbackPath`)
- `lib/core/di/injection.dart` — добавлен глобальный хелпер `ServerSession get currentSession => sl<SessionManager>().activeSession!`; proxy-фабрики для `sl<>()` удалены (больше не нужны)
- Миграция всех экранов и виджетов (~30 файлов): `sl<PostRepository>()` → `currentSession.postRepository`, `AppConfig.baseUrl` → `currentSession.baseUrl`, `AppConfig.oauthUrl` → `currentSession.oauthUrl` и т.д.
- `lib/presentation/widgets/user_avatar.dart` — `currentSession.getAuthToken()` и `currentSession.baseUrl` вместо глобальных
- `lib/presentation/widgets/message_markdown.dart` — `currentSession.baseUrl` для URL эмодзи/файлов
- `lib/presentation/utils/forward_helper.dart` — `currentSession.postRepository`
- `lib/core/observability/crash_reporting.dart` — per-session serverUrl
- `lib/core/utils/custom_emoji_cache.dart` — per-session baseUrl
- `lib/data/repositories/file_repository_impl.dart` — baseUrl через конструктор
- `lib/data/repositories/user_repository_impl.dart` — baseUrl через конструктор
- `integration_test/helpers/test_di.dart` — тестовые зависимости через `ServerSession.forTest()` + `SessionManager.setTestSession()`; мок `getUserStatuses` возвращает реальные статусы для предотвращения бесконечных pending timers
- `integration_test/mocks/fake_websocket.dart` — обновлён для per-session WS
- `test/network/api_client_test.dart` — передача `baseUrl` явно
- `test/repositories/file_repository_test.dart` — `baseUrl` через конструктор
- `test/repositories/user_repository_test.dart` — `baseUrl` через конструктор

**Тесты (8):**
- `test/presentation/server_session_provider_test.dart` — InheritedWidget доступ, extension, перестройка при смене сессии, свойства ServerSession (8 тестов)

**Итого после фаз 1+2+3:** 477 тестов, 0 ошибок, 0 новых lint-замечаний.

---

## Фаза 4: Параллельные WebSocket-соединения — DONE

**Цель:** поддерживать WS-соединения со всеми серверами одновременно.

**Что сделано:**

- `lib/main.dart` — `_initAllSessions()` вместо `_initActiveSession()`: создаёт `ServerSession` для **каждого** аккаунта при старте, не только для активного
- `lib/core/di/session_manager.dart` — добавлены:
  - `backgroundSessions` — геттер всех неактивных сессий
  - `connectBackgroundWebSockets()` — подключает WS для всех фоновых сессий с валидным токеном
  - `initBackgroundNotifications()` — инициализирует `NotificationBloc` фоновых сессий (без FCM-регистрации)
- `lib/core/di/server_session.dart` — добавлен `displayName` (из `ServerAccount.displayName` или hostname из URL); передаётся в `NotificationBloc`
- `lib/presentation/blocs/notification/notification_event.dart` — новый event `NotificationInitBackground(userId)`: легковесная инициализация без FCM-регистрации
- `lib/presentation/blocs/notification/notification_bloc.dart` — добавлены:
  - `serverDisplayName` параметр: при наличии — префикс `[serverName]` в заголовке уведомления
  - `_onInitBackground` обработчик: устанавливает userId, загружает per-channel фильтры, эмитит `NotificationReady` без запроса FCM-разрешений
- `lib/app.dart` — добавлены:
  - `_bgWsEventSubs` — подписки на WS-события фоновых сессий
  - `_connectBackgroundSessions()` — подключает WS + инициализирует NotificationBloc + подписывается на WS-события для всех фоновых сессий; вызывается после аутентификации активной сессии
  - `_cancelBackgroundSubscriptions()` — отмена подписок при переключении сервера или dispose

**Механизм параллельных WS:**
1. При старте `_initAllSessions()` создаёт `ServerSession` для каждого аккаунта
2. `App` аутентифицирует активную сессию → `AuthAuthenticated` → подключает WS активной сессии
3. `_connectBackgroundSessions()` → `SessionManager.connectBackgroundWebSockets()` проверяет токены фоновых сессий → подключает WS
4. `SessionManager.initBackgroundNotifications()` инициализирует `NotificationBloc` фоновых сессий с userId из SecureStorage
5. `App` подписывается на `wsEvents` каждой фоновой сессии → пробрасывает в их `NotificationBloc`
6. Фоновые `NotificationBloc` показывают local notifications с префиксом `[serverName]`
7. При переключении сервера → `_cancelBackgroundSubscriptions()` → `AuthCheckSession` → `_connectBackgroundSessions()` — подписки пересоздаются

**Бейдж-каунтер:**
Активная сессия обновляет бейдж через `ChannelsBloc._updateAppBadge()` (как раньше). Фоновые сессии показывают local notifications. Полная агрегация бейджей со всех серверов — в Phase 5 (push proxy управляет бейджем на стороне сервера).

**Тесты (15):**
- `test/core/session_manager_background_test.dart` — backgroundSessions, displayName propagation, connectBackgroundWebSockets, initBackgroundNotifications (8 тестов)
- `test/blocs/notification_bloc_background_test.dart` — NotificationInitBackground (без FCM, enabled/disabled, per-channel фильтры, own message filtering), serverDisplayName prefix (with/without/empty) (7 тестов)

**Итого после фаз 1+2+3+7+6+4:** 504 теста, 0 ошибок, 0 новых lint-замечаний.

**Итого после фаз 1+2+3+7+6+4+5:** 517 тестов, 0 ошибок, 0 новых lint-замечаний.

**Итого после фаз 1–8:** 524 теста, 0 ошибок, 0 новых lint-замечаний.

---

## Фаза 5: Push-уведомления от нескольких серверов — DONE

**Цель:** FCM-токен регистрируется на всех серверах; тап по уведомлению переключает на нужный сервер и открывает канал.

**Что сделано:**

### 5.1. Регистрация FCM-токена на всех серверах

- `lib/data/datasources/remote/notification_remote_datasource.dart` — исправлен `device_id` prefix: `Platform.isIOS ? 'apple' : 'android'` вместо хардкода `'android'`
- `lib/core/di/session_manager.dart` — добавлен `registerFcmTokenOnAllSessions(token)`: итерирует все сессии, для каждой с валидным auth-токеном вызывает `notificationRepository.registerDeviceToken(token)`, ошибки ловятся и логируются без прерывания
- `lib/core/di/session_manager.dart` — добавлен `findSessionByServerUrl(url)`: поиск сессии по URL сервера (для маршрутизации push), нормализует trailing slash
- `lib/app.dart` — `_registerFcmTokenOnAllServers()`: получает FCM-токен через `NotificationService.getToken()`, регистрирует на всех сессиях, подписывается на `onTokenRefresh` для авто-перерегистрации при ротации токена; вызывается после `AuthAuthenticated`

### 5.2. Маршрутизация push-уведомлений (tap handling)

- `lib/core/notifications/notification_service.dart` — `NotificationTapPayload` модель (channelId, postId, accountId, serverUrl)
- `lib/core/notifications/notification_service.dart` — `onNotificationTap` stream: объединяет тапы по локальным уведомлениям (`onDidReceiveNotificationResponse`) и FCM push (`FirebaseMessaging.onMessageOpenedApp`, `getInitialMessage`)
- `lib/core/notifications/notification_service.dart` — `showNotification()` принимает `accountId`, включает в JSON payload локального уведомления
- `lib/presentation/blocs/notification/notification_bloc.dart` — передаёт `_accountId` в `showNotification()` при генерации локальных уведомлений из WS-событий
- `lib/app.dart` — `_onNotificationTap(payload)`: определяет целевой сервер по `accountId` (local) или `serverUrl` (FCM push) → если не активный сервер, переключается через `ServerListCubit.switchServer()` и сохраняет `_pendingDeepLinkChannelId` → навигация после `AuthAuthenticated`; если тот же сервер — навигирует сразу

**Механизм регистрации FCM на всех серверах:**
1. Активная сессия аутентифицируется → `AuthAuthenticated`
2. `_registerFcmTokenOnAllServers()` → `NotificationService.getToken()` → `SessionManager.registerFcmTokenOnAllSessions(token)`
3. Для каждой сессии: проверка наличия auth-токена → `PUT /users/sessions/device_id` с `{device_id: "android|apple:<fcm_token>"}`
4. При ротации FCM-токена: `onTokenRefresh` → повторная регистрация на всех серверах

**Механизм маршрутизации push:**
1. Пользователь тапает push-уведомление (FCM) → `onMessageOpenedApp` / `getInitialMessage` → `_onFcmMessageTap` → payload с `server_url`, `channel_id`
2. Или тапает локальное уведомление (WS) → `onDidReceiveNotificationResponse` → payload с `accountId`, `channelId`
3. `_onNotificationTap`: определяет `targetAccountId` по `accountId` или через `findSessionByServerUrl(serverUrl)`
4. Если другой сервер: `switchServer(targetAccountId)` + `_pendingDeepLinkChannelId = channelId`
5. После `AuthAuthenticated`: `router.go('/chat/$channelId')` через `addPostFrameCallback`
6. Если тот же сервер: навигация сразу

**Тесты (13):**
- `test/core/session_manager_push_test.dart` — registerFcmTokenOnAllSessions (регистрация на всех, пропуск без токена, обработка ошибок, пустой список), findSessionByServerUrl (точный URL, trailing slash, неизвестный URL, пустой список, активная сессия) — 9 тестов
- `test/notifications/notification_tap_test.dart` — NotificationTapPayload (все поля, null поля), accountId в showNotification (с accountId, без accountId) — 4 теста

### 5.3. Notification channels (Android)

Отложено — текущий единый канал `messages` работает для всех серверов. Per-server каналы можно добавить позже при необходимости.

---

## Фаза 6: UI переключения серверов — DONE

**Цель:** UI для переключения между серверами, добавления и удаления серверов.

**Что сделано:**

- `lib/data/repositories/auth_repository_impl.dart` — добавлен параметр `accountId`; `saveAuthTokens`, `getCurrentUser`, `login`, `logout`, `hasValidSession` используют per-account ключи SecureStorage при наличии accountId, иначе legacy-методы
- `lib/core/di/server_session.dart` — передаёт `accountId` в `AuthRepositoryImpl`
- `lib/presentation/blocs/server/server_list_cubit.dart` — глобальный Cubit для управления списком серверов; состояние: `accounts`, `activeAccountId`; методы: `load()`, `switchServer()`, `addServer()`, `removeServer()`
- `lib/presentation/widgets/server_drawer.dart` — Drawer со списком серверов (аватар-буква, имя, хост), индикатором активного, кнопкой "+" и удалением по long-press
- `lib/presentation/screens/server/add_server_screen.dart` — экран добавления сервера: ввод URL → ping `/api/v4/system/ping` → создание `ServerAccount` → `addServer()` → переключение; дубликаты определяются и просто переключаются
- `lib/core/di/injection.dart` — зарегистрирован `ServerListCubit`
- `lib/app.dart` — `ServerListCubit` предоставлен через `MultiBlocProvider`; подписка на `stream` для перестроения виджет-дерева при смене сервера (обновление `_session`, `_appRouter`, `AuthCheckSession`)
- `lib/presentation/screens/channels/channels_screen.dart` — AppBar: аватар-буква сервера слева (виден при >1 сервере), по тапу открывается `ServerDrawer`; `drawer:` параметр на `Scaffold`
- `lib/presentation/screens/profile/profile_screen.dart` — кнопка "Сменить сервер" → "Добавить сервер"; удалён `_showChangeServerDialog` (полный restart больше не нужен)
- `lib/presentation/screens/server/server_url_screen.dart` — при первой настройке создаёт `ServerAccount` + `ServerSession` (раньше только сохранял URL)
- `lib/core/router/route_names.dart` — добавлен `/add-server`
- `lib/core/router/app_router.dart` — маршрут `AddServerScreen`

**Механизм переключения:**
1. Пользователь тапает на другой сервер в Drawer
2. `ServerListCubit.switchServer()` → `SessionManager.switchTo()` + `ServerAccountRepository.setActive()`
3. `App` слушает `ServerListCubit.stream` → обновляет `_session` → `setState`
4. `ValueKey(session.accountId)` на per-server `MultiBlocProvider` → полная перестройка виджет-дерева
5. Новая сессия: `AuthBloc.add(AuthCheckSession())` → загрузка данных

**Добавление сервера:**
1. `AddServerScreen` → ввод URL → ping → `ServerListCubit.addServer()`
2. Создаётся `ServerSession`, активируется
3. `App` перестраивается, `AuthBloc` — `AuthCheckSession` → нет токена → `AuthUnauthenticated` → redirect на `/auth`
4. OAuth/login → токены сохраняются в per-account ключи (благодаря `AuthRepositoryImpl.accountId`)

**Тесты (8):**
- `test/blocs/server_list_cubit_test.dart` — load, empty load, switchServer, switch same (no-op), addServer, removeServer (with fallback), removeServer last, initial state

**Итого после фаз 1+2+3+7+6:** 489 тестов, 0 ошибок, 0 новых lint-замечаний.

---

## Фаза 7: Изоляция per-server данных в SharedPreferences — DONE

**Цель:** per-server данные хранятся с префиксом `{accountId}_`, глобальные настройки — без.

**Что сделано:**

- `lib/core/storage/draft_storage.dart` — добавлен параметр `accountId`, ключ `drafts` → `drafts_{accountId}`; `DraftStorage` перенесён из глобального синглтона в `ServerSession`
- `lib/presentation/blocs/auth/auth_bloc.dart` — добавлен параметр `accountId`, ключ `selected_team_id` → `selected_team_id_{accountId}`
- `lib/presentation/blocs/notification/notification_bloc.dart` — добавлен параметр `accountId`, ключи `channel_notification_{channelId}` → `channel_notification_{accountId}_{channelId}`; загрузка per-channel фильтров по per-account префиксу
- `lib/presentation/screens/channel_info/channel_info_screen.dart` — `_ChannelNotificationSheet` использует per-account ключ через `currentSession.accountId`
- `lib/presentation/screens/chat/widgets/emoji_picker_sheet.dart` — ключ `recent_emojis` → `recent_emojis_{accountId}`
- `lib/presentation/screens/chat/widgets/message_input.dart` — аналогично per-account `recent_emojis`
- `lib/core/di/server_session.dart` — `DraftStorage(accountId)` в ServerSession; `AuthBloc` и `NotificationBloc` получают `accountId`
- `lib/core/di/injection.dart` — убрана глобальная регистрация `DraftStorage`
- `lib/presentation/screens/drafts/drafts_screen.dart` — `sl<DraftStorage>()` → `currentSession.draftStorage`
- `lib/core/storage/server_account_migration.dart` — миграция legacy ключей: `drafts`, `selected_team_id`, `recent_emojis`, `channel_notification_*` → per-account формат

**Per-account ключи:**
- `drafts_{accountId}` — черновики сообщений
- `selected_team_id_{accountId}` — выбранная команда
- `recent_emojis_{accountId}` — недавно использованные эмодзи
- `channel_notification_{accountId}_{channelId}` — per-channel настройки уведомлений

**Глобальные настройки (без изменений):**
- `notification_enabled`, `notification_filter` — глобальный флаг/фильтр уведомлений
- `theme_mode`, `app_locale` — тема и язык
- `biometric_enabled`, `onboarding_completed` — системные настройки
- `analytics_enabled`, `analytics_events` — аналитика
- `ff_local_*`, `ff_remote_*` — feature flags
- `server_accounts`, `active_server_id` — реестр аккаунтов

**Тесты (4 новых):**
- `test/storage/draft_storage_test.dart` — per-account изоляция, независимость от legacy (2 теста)
- `test/storage/server_account_migration_test.dart` — миграция SharedPreferences ключей, пропуск отсутствующих (2 теста)

**Итого после фаз 1+2+3+7:** 481 тест, 0 ошибок, 0 новых lint-замечаний.

---

## Фаза 8: OAuth-маршрутизация — DONE

**Цель:** при мульти-сервере знать, для какого сервера пришёл OAuth-колбэк, и направить токены в правильную сессию.

**Что сделано:**

- `lib/core/di/session_manager.dart` — добавлены:
  - `_pendingOAuthAccountId` — accountId сервера, для которого запущен OAuth
  - `startOAuth(accountId)` — устанавливает pending перед запуском браузера
  - `consumePendingOAuth()` — возвращает и очищает pending id
- `lib/app.dart` — OAuth deep link handling перенесён из `AuthScreen` сюда (App всегда живёт, в отличие от AuthScreen):
  - `_oauthLinkSub` — подписка на `AppLinks.uriLinkStream`
  - `_listenForOAuthDeepLinks()` — вызывается в `_initSession()`
  - `_onOAuthCallback(uri)` — извлекает MMAUTHTOKEN/MMCSRF, определяет целевую сессию через `consumePendingOAuth()` (fallback на активную), отправляет `AuthOAuthCompleted` в правильный AuthBloc; если целевая сессия не активна — переключается через `ServerListCubit`
- `lib/presentation/screens/auth/auth_screen.dart` — упрощён:
  - Удалены `AppLinks`, `_linkSub`, `_listenForDeepLinks()` (deep link теперь в App)
  - `_launchOAuth()` вызывает `SessionManager.startOAuth(currentSession.accountId)` перед запуском браузера

**Механизм:**
1. Пользователь тапает "Sign in with GitLab" → `_launchOAuth()` → `SessionManager.startOAuth(accountId)` → браузер открывается
2. Пользователь аутентифицируется в GitLab → браузер редиректит на `mmauth://oauth/callback?MMAUTHTOKEN=...&MMCSRF=...`
3. `App._onOAuthCallback()` → `consumePendingOAuth()` → находит целевую сессию → `AuthOAuthCompleted` в её AuthBloc
4. Если целевая сессия не активна → `ServerListCubit.switchServer()` → перестройка виджет-дерева
5. AuthBloc сохраняет токены, загружает пользователя → `AuthAuthenticated`

**Edge case:** если пользователь переключил сервер пока был в браузере, OAuth-колбэк всё равно попадёт в правильную сессию благодаря `pendingOAuthAccountId`.

**Тесты (7):**
- `test/core/session_manager_oauth_test.dart` — consumePendingOAuth без OAuth, startOAuth + consume, очистка после consume, перезапись pending id, независимость от activeSession, removeSession не очищает pending, dispose не очищает pending

---

## Порядок реализации

| Приоритет | Фаза | Описание | Статус |
|-----------|-------|----------|--------|
| 1 | Фаза 1 | ServerAccount, реестр, миграция хранилища | **DONE** |
| 2 | Фаза 2 | ServerSession, SessionManager, параметризация сети/БД | **DONE** |
| 3 | Фаза 3 | Перестройка виджетов, ServerSessionProvider | **DONE** |
| 4 | Фаза 7 | Изоляция SharedPreferences | **DONE** |
| 5 | Фаза 6 | UI переключения серверов | **DONE** |
| 6 | Фаза 4 | Параллельные WS-соединения | **DONE** |
| 7 | Фаза 5 | Push от нескольких серверов | **DONE** |
| 8 | Фаза 8 | OAuth-маршрутизация | **DONE** |

---

## Ключевые риски

1. **Потребление памяти.** Каждая `ServerSession` = Dio + WS + SQLite. Для 2-3 серверов допустимо. Для 10+ — нужна ленивая инициализация неактивных сессий (только WS для уведомлений).

2. ~~**Использование `AppConfig.serverUrl` по всей кодовой базе.** Требуется полный grep и замена на per-session значения (URL аватаров, файлов и т.д.).~~ Решено в фазе 3: все экраны и виджеты мигрированы на `currentSession.baseUrl` / `currentSession.serverUrl`.

3. ~~**Миграция SQLite.** Существующий `mgmess.db` нужно переименовать в `mgmess_{firstAccountId}.db`.~~ Решено: дефолтный конструктор `AppDatabase()` продолжает использовать `mgmess.db`; новые сессии создают `mgmess_{accountId}.db`. Миграция legacy БД будет в рамках перевода `main.dart` на SessionManager.

4. ~~**Dio `baseUrl` фиксирован в конструкторе.** Невозможно изменить runtime — отсюда необходимость per-server `ApiClient`.~~ Решено: `ApiClient` принимает опциональный `baseUrl`, каждая `ServerSession` создаёт свой экземпляр.

---

## Созданные файлы (фазы 1–8)

| Файл | Описание |
|------|----------|
| `lib/domain/entities/server_account.dart` | Equatable-сущность аккаунта сервера |
| `lib/domain/repositories/server_account_repository.dart` | Абстрактный интерфейс реестра серверов |
| `lib/data/repositories/server_account_repository_impl.dart` | Реализация на SharedPreferences |
| `lib/core/storage/server_account_migration.dart` | Миграция legacy → multi-server + SharedPreferences ключей |
| `lib/core/di/server_session.dart` | Per-server контейнер зависимостей + DraftStorage |
| `lib/core/di/session_manager.dart` | Управление сессиями |
| `lib/presentation/widgets/server_session_provider.dart` | InheritedWidget для текущей ServerSession |
| `test/models/server_account_test.dart` | Тесты ServerAccount |
| `test/repositories/server_account_repository_test.dart` | Тесты ServerAccountRepository |
| `test/storage/secure_storage_test.dart` | Тесты per-account SecureStorage |
| `test/storage/server_account_migration_test.dart` | Тесты миграции |
| `test/core/server_session_test.dart` | Тесты ServerSession |
| `test/core/session_manager_test.dart` | Тесты SessionManager |
| `test/network/api_client_per_account_test.dart` | Тесты ApiClient с accountId |
| `test/presentation/server_session_provider_test.dart` | Тесты ServerSessionProvider |
| `lib/presentation/blocs/server/server_list_cubit.dart` | Cubit управления списком серверов |
| `lib/presentation/widgets/server_drawer.dart` | Drawer переключения серверов |
| `lib/presentation/screens/server/add_server_screen.dart` | Экран добавления нового сервера |
| `test/blocs/server_list_cubit_test.dart` | Тесты ServerListCubit (8 тестов) |
| `test/core/session_manager_background_test.dart` | Тесты backgroundSessions, connectBackgroundWebSockets, initBackgroundNotifications (8 тестов) |
| `test/blocs/notification_bloc_background_test.dart` | Тесты NotificationInitBackground, serverDisplayName prefix (7 тестов) |
| `test/core/session_manager_push_test.dart` | Тесты registerFcmTokenOnAllSessions, findSessionByServerUrl (9 тестов) |
| `test/notifications/notification_tap_test.dart` | Тесты NotificationTapPayload, accountId в showNotification (4 теста) |
| `test/core/session_manager_oauth_test.dart` | Тесты startOAuth, consumePendingOAuth (7 тестов) |

## Изменённые файлы (фазы 1–8)

| Файл | Изменения |
|------|-----------|
| `lib/core/storage/draft_storage.dart` | Per-account ключ `drafts_{accountId}` |
| `lib/core/storage/secure_storage.dart` | Per-account методы + migration helpers |
| `lib/core/network/api_client.dart` | Опциональные `baseUrl`, `accountId`; per-account Auth interceptor |
| `lib/core/network/websocket_client.dart` | Опциональные `wsUrl`, `accountId`; per-account токен |
| `lib/data/datasources/local/app_database.dart` | `AppDatabase.named(dbFileName)`, параметризованный `_openConnection` |
| `lib/core/di/injection.dart` | Глобальные синглтоны + SessionManager + хелпер `currentSession`; убрана глобальная регистрация DraftStorage |
| `lib/main.dart` | Миграция + инициализация активной сессии |
| `lib/app.dart` | Двухуровневая структура виджетов с ServerSessionProvider |
| `lib/core/config/app_config.dart` | Удалены `baseUrl`, `wsUrl`, `oauthUrl` (теперь в ServerSession) |
| `lib/core/observability/crash_reporting.dart` | Per-session serverUrl |
| `lib/core/utils/custom_emoji_cache.dart` | Per-session baseUrl |
| `lib/data/repositories/file_repository_impl.dart` | baseUrl через конструктор |
| `lib/data/repositories/user_repository_impl.dart` | baseUrl через конструктор |
| `lib/presentation/widgets/user_avatar.dart` | `currentSession.getAuthToken()`, `currentSession.baseUrl` |
| `lib/presentation/widgets/user_display_name.dart` | Per-session доступ |
| `lib/presentation/widgets/message_markdown.dart` | `currentSession.baseUrl` для URL эмодзи/файлов |
| `lib/presentation/utils/forward_helper.dart` | `currentSession.postRepository` |
| `lib/presentation/blocs/auth/auth_bloc.dart` | Per-account `selected_team_id_{accountId}` |
| `lib/presentation/blocs/notification/notification_bloc.dart` | Per-account `channel_notification_{accountId}_{channelId}` |
| `lib/presentation/screens/auth/auth_screen.dart` | `currentSession.oauthUrl`, `currentSession.serverUrl` |
| `lib/presentation/screens/channels/channels_screen.dart` | `currentSession.channelRepository`, `currentSession.userRepository` |
| `lib/presentation/screens/channels/create_channel_screen.dart` | `currentSession.channelRepository` |
| `lib/presentation/screens/channels/create_group_dm_screen.dart` | `currentSession.userRepository` |
| `lib/presentation/screens/chat/chat_screen.dart` | `currentSession.postRepository` и другие per-session зависимости |
| `lib/presentation/screens/chat/widgets/channel_picker_sheet.dart` | Per-session доступ |
| `lib/presentation/screens/chat/widgets/emoji_picker_sheet.dart` | Per-session доступ + per-account recent_emojis |
| `lib/presentation/screens/chat/widgets/file_attachment_widget.dart` | Per-session baseUrl |
| `lib/presentation/screens/chat/widgets/message_bubble.dart` | Per-session доступ |
| `lib/presentation/screens/chat/widgets/message_input.dart` | Per-session доступ + per-account drafts/recent_emojis |
| `lib/presentation/screens/chat/widgets/pinned_messages_sheet.dart` | Per-session доступ |
| `lib/presentation/screens/chat/widgets/reactions_list_sheet.dart` | Per-session доступ |
| `lib/presentation/screens/channel_info/channel_files_screen.dart` | Per-session доступ |
| `lib/presentation/screens/channel_info/channel_info_screen.dart` | Per-session доступ + per-account channel notification key |
| `lib/presentation/screens/channel_info/channel_members_screen.dart` | Per-session доступ |
| `lib/presentation/screens/channel_info/edit_channel_screen.dart` | Per-session доступ |
| `lib/presentation/screens/media/media_viewer_screen.dart` | Per-session baseUrl |
| `lib/presentation/screens/mentions/mentions_screen.dart` | Per-session доступ |
| `lib/presentation/screens/profile/edit_profile_screen.dart` | Per-session доступ |
| `lib/presentation/screens/profile/profile_screen.dart` | Per-session serverUrl |
| `lib/presentation/screens/profile/user_profile_screen.dart` | Per-session доступ |
| `lib/presentation/screens/saved_messages/saved_messages_screen.dart` | Per-session доступ |
| `lib/presentation/screens/search/search_screen.dart` | Per-session доступ |
| `lib/presentation/screens/thread/thread_screen.dart` | Per-session доступ |
| `lib/presentation/screens/threads/threads_screen.dart` | Per-session доступ |
| `lib/presentation/screens/drafts/drafts_screen.dart` | `currentSession.draftStorage` |
| `integration_test/helpers/test_di.dart` | ServerSession.forTest() + SessionManager.setTestSession() |
| `integration_test/mocks/fake_secure_storage.dart` | Per-account методы |
| `integration_test/mocks/fake_websocket.dart` | Per-session WS |
| `test/network/api_client_test.dart` | Явная передача baseUrl |
| `test/repositories/file_repository_test.dart` | baseUrl через конструктор |
| `test/repositories/user_repository_test.dart` | baseUrl через конструктор |
| `lib/data/repositories/auth_repository_impl.dart` | Per-account saveAuthTokens/login/logout/hasValidSession |
| `lib/core/di/server_session.dart` | Передаёт accountId в AuthRepositoryImpl |
| `lib/core/di/injection.dart` | Зарегистрирован ServerListCubit |
| `lib/app.dart` | ServerListCubit в MultiBlocProvider + подписка на stream для перестроения |
| `lib/presentation/screens/channels/channels_screen.dart` | Аватар-буква сервера в AppBar + ServerDrawer |
| `lib/presentation/screens/profile/profile_screen.dart` | «Добавить сервер» вместо «Сменить сервер» |
| `lib/presentation/screens/server/server_url_screen.dart` | Создаёт ServerAccount при первой настройке |
| `lib/core/router/route_names.dart` | Маршрут `/add-server` |
| `lib/core/router/app_router.dart` | GoRoute для AddServerScreen |
| `lib/l10n/app_en.arb` | Строки servers/addServer/removeServer/... |
| `lib/l10n/app_ru.arb` | Русские строки servers/addServer/removeServer/... |
| `lib/core/di/server_session.dart` | Добавлен `displayName`, передаётся в NotificationBloc |
| `lib/core/di/session_manager.dart` | `backgroundSessions`, `connectBackgroundWebSockets()`, `initBackgroundNotifications()` |
| `lib/presentation/blocs/notification/notification_event.dart` | `NotificationInitBackground` event |
| `lib/presentation/blocs/notification/notification_bloc.dart` | `serverDisplayName` prefix, `_onInitBackground` handler |
| `lib/main.dart` | `_initAllSessions()` — сессии для всех аккаунтов |
| `lib/app.dart` | `_bgWsEventSubs`, `_connectBackgroundSessions()`, `_cancelBackgroundSubscriptions()` |
| `lib/data/datasources/remote/notification_remote_datasource.dart` | Platform-aware device_id prefix (`apple`/`android`) |
| `lib/core/di/session_manager.dart` | `registerFcmTokenOnAllSessions()`, `findSessionByServerUrl()` |
| `lib/core/notifications/notification_service.dart` | `NotificationTapPayload`, `onNotificationTap` stream, tap handling для local+FCM, `accountId` в `showNotification`, `dispose()` |
| `lib/presentation/blocs/notification/notification_bloc.dart` | Передаёт `_accountId` в `showNotification` |
| `lib/app.dart` | `_registerFcmTokenOnAllServers()`, `_onNotificationTap()`, `_pendingDeepLinkChannelId`, `_tokenRefreshSub`, `_notificationTapSub` |
| `integration_test/mocks/fake_notification_service.dart` | Обновлён для `accountId`, `onNotificationTap`, `dispose()` |
| `lib/core/di/session_manager.dart` | `startOAuth()`, `consumePendingOAuth()` для OAuth-маршрутизации |
| `lib/app.dart` | `_oauthLinkSub`, `_listenForOAuthDeepLinks()`, `_onOAuthCallback()` — OAuth deep link handling |
| `lib/presentation/screens/auth/auth_screen.dart` | Удалён deep link listener, добавлен `startOAuth()` перед OAuth |
