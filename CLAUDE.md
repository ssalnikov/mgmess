# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MGMess is a Flutter mobile Mattermost client for MyGames corporate server (`https://mm.my.games`). It supports GitLab OAuth authentication, real-time messaging via WebSocket, file sharing, read receipts ("seens" — custom MyGames backend extension), saved messages, mentions, push notifications (FCM), pinned messages, haptic feedback, and offline mode with local database (Drift/SQLite). Targets iOS and Android.

## Commands

```bash
# Run all tests — unit + integration (264 tests)
flutter test

# Run only unit tests (239 tests)
flutter test test/

# Run only integration tests as widget tests (25 tests, no device required)
flutter test test/integration_runner_test.dart

# Run integration tests on device/simulator
flutter test integration_test/scenarios/ -d <device_id>

# Run a single test file
flutter test test/blocs/auth_bloc_test.dart

# Run tests with verbose output
flutter test --reporter expanded

# Run tests with coverage
flutter test --coverage

# Static analysis
flutter analyze

# Build
flutter build apk
flutter build ios
```

## Architecture

Clean Architecture with three layers — all cross-layer calls go through abstract repository contracts returning `Either<Failure, T>` (dartz).

Локальная БД (Drift/SQLite):
`AppDatabase` (`lib/data/datasources/local/app_database.dart`) с таблицами Posts, Channels, Users. Каждая сущность имеет DAO + Mapper. Репозитории используют `NetworkInfo` для выбора источника: онлайн → API + фоновый кеш, офлайн → локальная БД, ошибка сервера → fallback на кеш. `SendQueueService` отправляет pending-посты при восстановлении сети. При добавлении новых кешируемых сущностей: создай таблицу в `app_database.dart`, DAO, Mapper и LocalDataSource.

UI Performance:
Чаты — это длинные списки.
Инструкция: "При рендеринге списка сообщений всегда используй ListView.builder или SliverList. Не используй ShrinkWrap без необходимости".

**Domain** (`lib/domain/`) — Entities and abstract repository interfaces. Pure Dart, no framework dependencies. The `Post` entity uses `metadata` (not `props`) to avoid conflict with `Equatable.props`.

**Data** (`lib/data/`) — Models (DTOs with `fromJson`/`toJson`), remote data sources (Dio-based), local data sources (Drift-based for offline cache), repository implementations, and services (`WsPostParserImpl`, `SendQueueService`). Mattermost PostList responses use `{order: [...], posts: {...}}` format — `PostRemoteDataSource` handles this mapping.

**Presentation** (`lib/presentation/`) — BLoC state management, screens, and widgets.

### State Management (BLoC)

Global BLoCs (live for app lifetime, provided in `App` via `MultiBlocProvider`):
- `AuthBloc` — session lifecycle, OAuth, logout
- `WebSocketBloc` — WS connection, broadcasts `wsEvents` stream to other blocs
- `ConnectivityCubit` — network state
- `NotificationBloc` — FCM token lifecycle, WS events → local notifications, active channel suppression
- `UserStatusCubit` — user statuses (online/away/dnd/offline), batched fetching, WS `status_change` events

Screen-scoped BLoCs (created in screen `initState`, disposed on screen disposal):
- `ChannelsBloc` — channel list, search, WS unread updates
- `ChatBloc` — messages, optimistic send, pagination, typing indicator, pin/unpin, scroll-to-message with highlight
- `PinnedMessagesBloc` — pinned messages list per channel with unpin
- `SavedMessagesBloc`, `MentionsBloc`

Pattern: other blocs subscribe to `WebSocketBloc.wsEvents` stream and filter events by `channelId`/event type.

### Dependency Injection

GetIt service locator in `lib/core/di/injection.dart`. Registration order: Core (storage, API, WS, NetworkInfo) -> Database (AppDatabase) -> DAOs -> Local DataSources -> Remote DataSources -> Services (WsPostParser, SendQueueService) -> Repositories (registered by abstract type) -> BLoCs. Access via `sl<Type>()`.

### Networking

- `ApiClient` (Dio) with three interceptors: `_AuthInterceptor` (Bearer token + CSRF, clears storage on 401), `_RetryInterceptor` (retries 5xx up to 3 times, linear backoff), `_LoggingInterceptor`
- `WebSocketClient` — connects to `wss://mm.my.games/api/v4/websocket`, sends `authentication_challenge`, handles `hello`, reconnects with exponential backoff (1s->2s->4s->8s->16s->30s max)
- WS event `data.post` fields for `posted`/`post_edited`/`post_deleted` are **JSON strings** requiring `jsonDecode`

### Auth Flow

GitLab OAuth via system browser: open `https://mm.my.games/oauth/gitlab/mobile_login?redirect_to=mgmess://oauth/callback` -> GitLab auth -> server redirects to `mgmess://oauth/callback?MMAUTHTOKEN=...&MMCSRF=...` -> app intercepts via `app_links`, stores tokens in `flutter_secure_storage`.

Server must have `"mgmess://"` in `NativeAppSettings.AppCustomURLSchemes`.

### Routing

GoRouter in `lib/core/router/app_router.dart` with auth redirect guard. ShellRoute for bottom nav (channels, saved, mentions, profile). Redirects to `/auth` when `AuthUnauthenticated`.

### Push Notifications (FCM)

Firebase Cloud Messaging for push notifications. `Firebase.initializeApp()` is wrapped in try/catch — app works without Firebase configs (google-services.json / GoogleService-Info.plist), but push is disabled.

- `NotificationService` (`lib/core/notifications/`) — FCM init, permissions, local notification display via `flutter_local_notifications`
- `NotificationRemoteDataSource` — registers FCM token with Mattermost via `PUT /users/sessions/device_id` (device_id format: `android:<fcm_token>`)
- `NotificationBloc` — global BLoC, subscribes to `WebSocketBloc.wsEvents`, shows local notifications for `posted` events when app is in foreground. Suppresses notifications for active channel and own messages. Filter settings (all / mentions+DM / DM only) stored in `SharedPreferences`.
- Notification settings screen at `/profile/notifications`

Setup: see `docs/push_notifications.md`.

### Pinned Messages

API `GET /channels/{id}/pinned` returns PostList `{order, posts}`. Pin/unpin via `POST /posts/{id}/pin` and `POST /posts/{id}/unpin`. `Post.isPinned` and `Post.copyWith(isPinned:)` are used throughout.

- `PinnedMessagesBloc` (`lib/presentation/screens/chat/widgets/pinned_messages_bloc.dart`) — loads pinned posts, handles unpin, groups by date
- `PinnedMessagesSheet` (`lib/presentation/screens/chat/widgets/pinned_messages_sheet.dart`) — DraggableScrollableSheet showing pinned messages with unpin buttons
- Pin icon in `ChatScreen` AppBar opens the sheet; long-press context menu offers Pin/Unpin actions
- Pinned messages display a "Pinned" indicator badge in `MessageBubble`

### Hero Animations

`UserAvatar` supports optional `heroTag` parameter for Hero transitions. Used for DM channel avatars — avatar animates from channel list to chat AppBar. `dmUserId` is passed via GoRouter extra to `ChatScreen`.

### Haptic Feedback

`HapticFeedback` is used across the app: `lightImpact()` on message long-press and send, `selectionClick()` on context menu actions and pull-to-refresh.

### Thread-to-Channel Navigation

ThreadScreen has a "Show in channel" button (`Icons.open_in_new`) that navigates to ChatScreen with `scrollToPostId`. ChatBloc handles `ScrollToMessage` event (loads surrounding posts if target not in view) and `ClearHighlight` (auto-clears after 3s). MessageBubble animates highlight via `TweenAnimationBuilder`.

### Read-Only Channels

Channels can be read-only based on Mattermost channel schemes. `ChatScreen` calls `ChannelRepository.canUserPost(channelId, userId)` on init. The check: if channel is archived (`deleteAt > 0`) → read-only; if user is `scheme_admin` → can post; if channel has no custom `scheme_id` → can post (default); otherwise fetches scheme's `default_channel_user_role` and checks for `create_post` permission. When `canPost` is false, a read-only banner replaces `MessageInput`.

- `Channel.schemeId` — parsed from `scheme_id` in Mattermost API response
- `ChannelRemoteDataSource.getSchemeUserRoleName()` / `getRolePermissions()` — fetch scheme and role data
- API endpoints: `GET /schemes/{id}`, `GET /roles/name/{name}`

### Channel Files

`ChannelFilesScreen` (`/channel/:channelId/files`) shows all files shared in a channel. Entry point: ListTile in `ChannelInfoScreen`. Uses `FileRepository.getChannelFiles()` which scans channel posts via pagination and extracts file attachments from post metadata. `ChannelFilesCubit` manages state with filter tabs (All / Images / Documents) and infinite scroll.

### Custom Backend: Seens (Read Receipts)

MyGames extension endpoints: `GET /api/v4/channels/{id}/seens`, `GET /api/v4/posts/{id}/seens`. WS events: `channel_seens_updated`, `thread_seens_updated`. Mobile marker constant: `WebsocketMessagePropertySeensMark = "its_need_to_mark_seen_for_mobile"`.

## Testing Conventions

### Unit Tests (`test/`)

- Test files: `test/<category>/<unit>_test.dart`
- BLoC tests use `blocTest` from `bloc_test` package with `build`/`seed`/`act`/`expect` pattern
- Mocks via `mocktail`: `class MockX extends Mock implements X {}`
- Repositories tested with mocked data sources, verifying both success and error paths
- Model tests cover `fromJson`, `toJson`, computed properties, and empty/missing field edge cases
- All BLoCs/Cubits covered: AuthBloc, WebSocketBloc, ChannelsBloc, ChatBloc, NotificationBloc, ThreadsBloc, ConnectivityCubit, UserStatusCubit
- All repositories covered: Auth, Post (online/offline/fallback), Channel (enrichment), User (cache-first), File, Seens, Notification
- Services covered: WsPostParserImpl, SendQueueService (pending posts, connectivity)
- Network covered: ApiClient interceptors (auth headers, 401 clearance, retry on 5xx)

### Integration Tests (`integration_test/`)

Full-screen user flow testing with mocked repositories via GetIt. All 7 repositories (`AuthRepository`, `ChannelRepository`, `PostRepository`, `UserRepository`, `FileRepository`, `SeensRepository`, `NotificationRepository`) are replaced with `mocktail` mocks. WebSocket is faked via `FakeWebSocketClient` with `simulateEvent()` for controlled WS event injection.

Structure:
- `mocks/` — `MockXRepository` (mocktail), `FakeWebSocketClient`, `FakeSecureStorage`, `FakeNotificationService`
- `fixtures/` — `test_data.dart` (entities), `ws_event_factory.dart` (WS event builders)
- `helpers/` — `test_di.dart` (GetIt setup with mocks), `test_app.dart` (scenario setup helpers), `pump_helpers.dart` (WidgetTester extensions)
- `scenarios/` — test files per user flow (auth, channels, chat, WS, pin, search, threads, edit/delete)
- `patrol/` — Patrol tests for native interactions (OAuth via system browser)

Runner: `test/integration_runner_test.dart` imports all scenarios so they can run as regular widget tests without a device via `flutter test test/integration_runner_test.dart`.

When adding a new integration test scenario:
1. Create `integration_test/scenarios/<name>_test.dart`
2. Add import + `<name>.main()` call in `test/integration_runner_test.dart`
3. Use `createTestApp()` + `setupXxx()` helpers from `test_app.dart`
4. Use `when(() => mocks.xxxRepository.method(...))` for scenario-specific stubs

## Key Configuration

- Server URL: `lib/core/config/app_config.dart` — `AppConfig.serverUrl`
- Deep link scheme: `mgmess://` — configured in `AndroidManifest.xml` and `ios/Runner/Info.plist`
- Token storage keys: `mm_auth_token`, `mm_csrf_token`, `mm_user_id` in `SecureStorage`
- Firebase: requires `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` (not in repo — see `docs/push_notifications.md`)
- Notification prefs: `notification_enabled` (bool), `notification_filter` (string: all/mentions_dm/dm_only) in `SharedPreferences`

## Critical Instructions
- When modifying models, ALWAYS run the build runner command immediately after.
- For chat lists, ensure optimized rendering (const constructors, keys).
- Never commit code with linter errors.

## Documentation

Russian-language docs in `docs/`: architecture.md, authentication.md, api.md, websocket.md, state_management.md, testing.md (unit + integration), server_setup.md, push_notifications.md.
