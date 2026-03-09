# Observability (Crash Reporting + Аналитика)

## Обзор

Система observability MGMess состоит из двух сервисов:

| Сервис | Класс | Файл | Назначение |
|--------|-------|------|------------|
| Crash Reporting | `CrashReporting` | `lib/core/observability/crash_reporting.dart` | Перехват крешей, необработанных исключений, breadcrumbs |
| Analytics | `AnalyticsService` | `lib/core/observability/analytics_service.dart` | Трекинг пользовательских событий, метрики использования |

Оба сервиса работают по принципу **graceful degradation**: если не настроены — приложение работает нормально, ничего не ломается.

```
┌──────────────────────────────────────────────┐
│                  main.dart                    │
│  CrashReporting.init() оборачивает runApp()  │
│  AnalyticsService.init() загружает настройки  │
├──────────────────────────────────────────────┤
│               app.dart                        │
│  AuthAuthenticated → setUser() + trackLogin() │
│  AuthUnauthenticated → clearUser() + logout() │
├──────────────────────────────────────────────┤
│            api_client.dart                    │
│  HTTP breadcrumbs (onRequest, onError)        │
└──────────────────────────────────────────────┘
```

---

## 1. Crash Reporting (Sentry)

### Настройка

Crash reporting работает через [Sentry Flutter SDK](https://docs.sentry.io/platforms/flutter/). По умолчанию **отключен** (DSN пустой) — чтобы включить, передайте DSN при инициализации.

#### Шаг 1: Получить DSN

Создайте проект в [Sentry](https://sentry.io/) (или self-hosted) и скопируйте DSN вида:
```
https://<key>@<org>.ingest.sentry.io/<project-id>
```

#### Шаг 2: Установить DSN

В `lib/core/observability/crash_reporting.dart` замените значение `_defaultDsn`:

```dart
static const String _defaultDsn = 'https://your-key@sentry.io/your-project-id';
```

Или передайте через параметр:
```dart
await CrashReporting.init(
  dsn: 'https://your-key@sentry.io/your-project-id',
  appRunner: () => runApp(const RestartWidget(child: App())),
);
```

#### Шаг 3: Проверить

В debug-режиме события **не отправляются** (фильтр в `_beforeSend`). Для проверки:
```dart
// Временно закомментировать фильтр в _beforeSend:
// if (kDebugMode) return null;
CrashReporting.reportMessage('Test event');
```

### API

```dart
// Инициализация (main.dart) — оборачивает runApp
await CrashReporting.init(
  appRunner: () => runApp(const App()),
);

// Установить пользователя (при аутентификации)
CrashReporting.setUser(userId: 'user123', username: 'johndoe');

// Очистить пользователя (при logout)
CrashReporting.clearUser();

// Добавить breadcrumb (отслеживание действий перед крешем)
CrashReporting.addBreadcrumb(
  category: 'navigation',
  message: 'Opened channel #general',
  data: {'channelId': 'abc123'},
);

// Отправить пойманное исключение
CrashReporting.reportError(
  exception,
  stackTrace: stackTrace,
  context: 'chat_bloc',
  extra: {'channelId': 'abc123'},
);

// Отправить сообщение (не исключение)
CrashReporting.reportMessage('WebSocket reconnect failed 3 times');
```

### HTTP Breadcrumbs

`_LoggingInterceptor` в `api_client.dart` автоматически пишет breadcrumbs для каждого HTTP-запроса:

```
→ GET /users/me                    # onRequest
← 200 /users/me                    # onResponse (нет breadcrumb, только лог)
✗ 500 /channels/abc/posts: timeout # onError → breadcrumb с level=error
```

### Конфигурация

| Параметр | Значение | Описание |
|----------|----------|----------|
| `environment` | `production` / `development` | По `kReleaseMode` |
| `tracesSampleRate` | 0.2 (prod) / 1.0 (dev) | Частота отправки performance traces |
| `attachScreenshot` | `true` | Прикрепляет скриншот при креше |
| `sendDefaultPii` | `false` | Не отправляет IP, email автоматически |

### Что не отправляется

- События в debug-режиме (`kDebugMode = true`)
- PII данные (email, IP — `sendDefaultPii: false`)
- Только userId и username устанавливаются явно через `setUser()`

---

## 2. Analytics Service

### Обзор

Легковесный сервис трекинга событий. Хранит события локально в `SharedPreferences`. Не требует внешних зависимостей (Firebase Analytics / PostHog и т.п.).

### Настройка

Сервис регистрируется в DI (`injection.dart`) и инициализируется в `main.dart`:

```dart
// injection.dart
sl.registerLazySingleton(() => AnalyticsService());

// main.dart
await sl<AnalyticsService>().init();
```

### Отслеживаемые события

| Событие | Метод | Свойства | Где вызывается |
|---------|-------|----------|----------------|
| `login` | `trackLogin()` | method (oauth/email/session) | `app.dart` — AuthAuthenticated |
| `logout` | `trackLogout()` | — | `app.dart` — AuthUnauthenticated |
| `channel_opened` | `trackChannelOpened()` | channel_id, type | При навигации в чат |
| `message_sent` | `trackMessageSent()` | channel_id, has_files | При отправке сообщения |
| `search` | `trackSearch()` | query_length, result_count | При поиске (не хранит текст запроса!) |
| `file_uploaded` | `trackFileUploaded()` | mime_type | При загрузке файла |
| `reaction_added` | `trackReactionAdded()` | emoji | При добавлении реакции |
| `thread_opened` | `trackThreadOpened()` | post_id | При открытии треда |
| `push_received` | `trackPushReceived()` | — | При получении push |
| `screen_view` | `trackScreenView()` | screen | При переходе на экран |
| `error` | `trackError()` | source, message | При ошибках |
| `channel_created` | `trackChannelCreated()` | type | При создании канала |
| `feature_flag_evaluated` | `trackFeatureFlagEvaluated()` | flag, value | При проверке feature flag |

### Приватность данных

- Текст поискового запроса **не хранится** — только длина (`query_length`)
- Содержимое сообщений **не хранится**
- Нет PII (email, имена, пароли)
- Хранятся только: channel_id, post_id, user_id (анонимные идентификаторы)

### Управление

```dart
final analytics = sl<AnalyticsService>();

// Включить/выключить сбор
await analytics.setEnabled(false);
print(analytics.isEnabled); // false

// Получить все сохранённые события (для экспорта)
final events = await analytics.getStoredEvents();

// Количество сохранённых событий
final count = await analytics.storedEventCount;

// Очистить (после успешной выгрузки на сервер)
await analytics.clearStoredEvents();
```

### Хранение

| Параметр | Значение |
|----------|----------|
| Ключ SharedPreferences | `analytics_events` |
| Формат | `List<String>` (JSON-строки) |
| Макс. событий | 500 (FIFO — старые удаляются) |
| Opt-in ключ | `analytics_enabled` (bool) |

### Формат события

```json
{
  "event": "message_sent",
  "timestamp": "2026-03-09T14:30:00.000Z",
  "properties": {
    "channel_id": "abc123",
    "has_files": false
  }
}
```

### Интеграция с бэкендом (будущее)

Для отправки событий на сервер аналитики, реализуйте batch-отправку:

```dart
final events = await analytics.getStoredEvents();
if (events.isNotEmpty) {
  await apiClient.dio.post('/analytics/events', data: events);
  await analytics.clearStoredEvents();
}
```

---

## 3. Целевые метрики

| Метрика | Целевое значение | Источник |
|---------|------------------|----------|
| Crash-free rate | > 99.5% | Sentry |
| D7 Retention | > 60% | Analytics (login events) |
| Message send success | > 99% | Analytics + SendQueueService |
| WS reconnect time | < 5s (p95) | Sentry breadcrumbs |
| App launch to chat | < 2s | Sentry performance traces |
| Search usage | > 30% DAU | Analytics (search events) |

---

## 4. Зависимости

| Пакет | Версия | Назначение |
|-------|--------|------------|
| `sentry_flutter` | ^8.12.0 | Crash reporting + performance |
| `shared_preferences` | ^2.5.3 | Хранение аналитики (уже в проекте) |
| `logger` | ^2.5.0 | Debug-логирование аналитики (уже в проекте) |

---

## 5. Тестирование

### CrashReporting (`test/core/crash_reporting_test.dart`)

10 тестов:
- `isEnabled` false при пустом DSN
- `init` запускает appRunner даже без DSN
- `setUser`, `clearUser`, `addBreadcrumb`, `reportError`, `reportMessage` — no-op при отключенном Sentry
- `SentryHttpBreadcrumbInterceptor` — не бросает при отключенном Sentry

### AnalyticsService (`test/core/analytics_service_test.dart`)

14 тестов:
- Включен по умолчанию, можно отключить, состояние персистится
- Каждый метод трекинга сохраняет событие
- Поиск хранит длину запроса, а не содержимое
- При отключенном сервисе события не сохраняются
- `clearStoredEvents`, `storedEventCount` работают корректно
- Все 13 методов трекинга работают
- Лимит хранения (500 событий) соблюдается

---

## 6. Feature Flag интеграция

Feature flags `FeatureFlag.crashReporting` и `FeatureFlag.analytics` позволяют отключать observability-сервисы через удалённую конфигурацию. См. [Feature Flags](feature_flags.md).
