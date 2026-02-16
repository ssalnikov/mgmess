# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MGMess is a Flutter mobile Mattermost client for MyGames corporate server (`https://mm.my.games`). It supports GitLab OAuth authentication, real-time messaging via WebSocket, file sharing, read receipts ("seens" — custom MyGames backend extension), saved messages, mentions, and push notifications (FCM). Targets iOS and Android.

## Commands

```bash
# Run all tests (82 tests)
flutter test

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

**Domain** (`lib/domain/`) — Entities and abstract repository interfaces. Pure Dart, no framework dependencies. The `Post` entity uses `metadata` (not `props`) to avoid conflict with `Equatable.props`.

**Data** (`lib/data/`) — Models (DTOs with `fromJson`/`toJson`), remote data sources (Dio-based), and repository implementations. Mattermost PostList responses use `{order: [...], posts: {...}}` format — `PostRemoteDataSource` handles this mapping.

**Presentation** (`lib/presentation/`) — BLoC state management, screens, and widgets.

### State Management (BLoC)

Global BLoCs (live for app lifetime, provided in `App` via `MultiBlocProvider`):
- `AuthBloc` — session lifecycle, OAuth, logout
- `WebSocketBloc` — WS connection, broadcasts `wsEvents` stream to other blocs
- `ConnectivityCubit` — network state
- `NotificationBloc` — FCM token lifecycle, WS events → local notifications, active channel suppression

Screen-scoped BLoCs (created in screen `initState`, disposed on screen disposal):
- `ChannelsBloc` — channel list, search, WS unread updates
- `ChatBloc` — messages, optimistic send, pagination, typing indicator
- `SavedMessagesBloc`, `MentionsBloc`

Pattern: other blocs subscribe to `WebSocketBloc.wsEvents` stream and filter events by `channelId`/event type.

### Dependency Injection

GetIt service locator in `lib/core/di/injection.dart`. Registration order: Core (storage, API, WS) -> DataSources -> Repositories (registered by abstract type) -> BLoCs. Access via `sl<Type>()`.

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

### Custom Backend: Seens (Read Receipts)

MyGames extension endpoints: `GET /api/v4/channels/{id}/seens`, `GET /api/v4/posts/{id}/seens`. WS events: `channel_seens_updated`, `thread_seens_updated`. Mobile marker constant: `WebsocketMessagePropertySeensMark = "its_need_to_mark_seen_for_mobile"`.

## Testing Conventions

- Test files: `test/<category>/<unit>_test.dart`
- BLoC tests use `blocTest` from `bloc_test` package with `build`/`seed`/`act`/`expect` pattern
- Mocks via `mocktail`: `class MockX extends Mock implements X {}`
- Repositories tested with mocked data sources, verifying both success and error paths
- Model tests cover `fromJson`, `toJson`, computed properties, and empty/missing field edge cases

## Key Configuration

- Server URL: `lib/core/config/app_config.dart` — `AppConfig.serverUrl`
- Deep link scheme: `mgmess://` — configured in `AndroidManifest.xml` and `ios/Runner/Info.plist`
- Token storage keys: `mm_auth_token`, `mm_csrf_token`, `mm_user_id` in `SecureStorage`
- Firebase: requires `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` (not in repo — see `docs/push_notifications.md`)
- Notification prefs: `notification_enabled` (bool), `notification_filter` (string: all/mentions_dm/dm_only) in `SharedPreferences`

## Git

- Do NOT add `Co-Authored-By` lines to commit messages.

## Documentation

Russian-language docs in `docs/`: architecture.md, authentication.md, api.md, websocket.md, state_management.md, testing.md, server_setup.md, push_notifications.md.
