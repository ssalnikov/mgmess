# Тестирование

## Обзор

Проект использует двухуровневую стратегию тестирования: unit-тесты для изолированных компонентов и интеграционные тесты для полных пользовательских сценариев.

| Пакет | Назначение |
|-------|------------|
| `flutter_test` | Базовый фреймворк тестирования |
| `bloc_test` | Декларативные тесты для BLoC/Cubit |
| `mocktail` | Мок-объекты (без кодогенерации) |
| `integration_test` | Интеграционные тесты (Flutter SDK) |
| `patrol` | Нативные E2E-тесты (OAuth через браузер) |

**Итого: 264 теста** (239 unit + 25 integration)

## Структура тестов

```
test/
├── models/                          # Unit-тесты моделей
│   ├── user_model_test.dart         # 9 тестов
│   ├── channel_model_test.dart      # 9 тестов
│   ├── post_model_test.dart         # 14 тестов
│   ├── file_info_model_test.dart    # 9 тестов
│   ├── user_thread_model_test.dart  # тесты модели тредов
│   └── draft_test.dart              # тесты модели черновиков
├── blocs/                           # Unit-тесты BLoC/Cubit
│   ├── auth_bloc_test.dart          # 6 тестов
│   ├── channels_bloc_test.dart      # 4 теста
│   ├── chat_bloc_test.dart          # 6 тестов
│   ├── notification_bloc_test.dart  # тесты NotificationBloc
│   ├── threads_bloc_test.dart       # тесты ThreadsBloc
│   ├── websocket_bloc_test.dart     # 9 тестов — connect/disconnect, wsEvents трансляция, sendTyping
│   ├── connectivity_cubit_test.dart # 5 тестов — подписка на изменения сети, close
│   └── user_status_cubit_test.dart  # 11 тестов — fetchStatuses, WS status_change, батчинг requestStatus
├── repositories/                    # Unit-тесты репозиториев
│   ├── auth_repository_test.dart    # 7 тестов
│   ├── notification_repository_test.dart # тесты NotificationRepository
│   ├── post_repository_test.dart    # 32 теста — online/offline/fallback, createPost pending, CRUD
│   ├── channel_repository_test.dart # 16 тестов — enrichment membership, offline, mute/unmute
│   ├── user_repository_test.dart    # 16 тестов — cache-first getUser, autocomplete, statuses
│   ├── seens_repository_test.dart   # 4 теста — getChannelSeens, getPostSeens
│   └── file_repository_test.dart    # 7 тестов — uploadFiles, getFileInfo, URL-методы
├── services/                        # Unit-тесты сервисов
│   ├── ws_post_parser_test.dart     # 9 тестов — парсинг JSON, forwarded, priority, невалидный вход
│   └── send_queue_service_test.dart # 9 тестов — pending-посты, connectivity, ошибки, dispose
├── network/                         # Unit-тесты сетевого слоя
│   └── api_client_test.dart         # 7 тестов — AuthInterceptor (Bearer, CSRF, 401), конфигурация
├── storage/                         # Unit-тесты хранилищ
│   └── draft_storage_test.dart      # тесты DraftStorage
├── widget_test.dart                 # Unit-тесты утилит (WsEvent, DateFormatter) — 8 тестов
└── integration_runner_test.dart     # Runner для интеграционных тестов (без устройства)

integration_test/
├── mocks/                           # Моки и фейки
│   ├── mock_repositories.dart       # MockXRepository для всех 7 репозиториев
│   ├── fake_websocket.dart          # FakeWebSocketClient с simulateEvent()
│   ├── fake_secure_storage.dart     # In-memory SecureStorage
│   └── fake_notification_service.dart # Фейковый NotificationService (без Firebase)
├── fixtures/                        # Тестовые данные
│   ├── test_data.dart               # testUser, testTeam, testChannels, testPosts
│   └── ws_event_factory.dart        # createPostedEvent(), createPostEditedEvent() и др.
├── helpers/                         # Утилиты
│   ├── test_di.dart                 # initTestDependencies() — GetIt с моками
│   ├── test_app.dart                # createTestApp(), setupAuthenticatedState() и др.
│   └── pump_helpers.dart            # pumpAndSettle2(), pumpN(), waitForText()
├── scenarios/                       # Тестовые сценарии (25 тестов)
│   ├── auth_flow_test.dart          # 5 тестов: авторизация, логин, восстановление сессии
│   ├── channel_list_test.dart       # 4 теста: загрузка каналов, навигация в чат
│   ├── send_message_test.dart       # 2 теста: отправка сообщения
│   ├── receive_message_ws_test.dart # 4 теста: получение через WS, typing, post_edited
│   ├── pin_unpin_test.dart          # 3 теста: pin/unpin через контекстное меню
│   ├── search_channels_test.dart    # 3 теста: поиск, очистка, пустой результат
│   ├── thread_navigation_test.dart  # 1 тест: навигация в тред
│   └── edit_delete_message_test.dart # 3 теста: редактирование, удаление, проверка прав
└── patrol/                          # Patrol (нативные E2E)
    └── oauth_browser_test.dart      # OAuth через системный браузер (требует устройство)
```

## Запуск

```bash
# Все тесты (unit + integration)
flutter test

# Только unit-тесты
flutter test test/

# Только интеграционные тесты (без устройства, как widget-тесты)
flutter test test/integration_runner_test.dart

# Интеграционные тесты на устройстве/симуляторе
flutter test integration_test/scenarios/ -d <device_id>

# Конкретный сценарий на устройстве
flutter test integration_test/scenarios/auth_flow_test.dart -d <device_id>

# Конкретный файл
flutter test test/blocs/auth_bloc_test.dart

# С подробным выводом
flutter test --reporter expanded

# С покрытием
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Patrol (требует устройство и Patrol CLI)
patrol test integration_test/patrol/
```

## Тесты моделей

Проверяют корректность сериализации/десериализации JSON и вычисляемые свойства.

### Что тестируется

- `fromJson` — парсинг JSON из API в объект
- `toJson` — сериализация для отправки на сервер
- Вычисляемые свойства (`displayName`, `isDeleted`, `hasUnread`, `isImage`, `sizeFormatted`)
- Граничные случаи: пустые поля, отсутствующие ключи, пустой JSON

### Пример

```dart
test('fromJson creates correct model', () {
  final user = UserModel.fromJson({
    'id': 'user123',
    'username': 'johndoe',
    'email': 'john@example.com',
    'first_name': 'John',
    'last_name': 'Doe',
  });
  expect(user.id, 'user123');
  expect(user.displayName, 'John Doe');
});

test('fromJson handles empty map', () {
  final user = UserModel.fromJson({});
  expect(user.id, '');
  expect(user.username, '');
});
```

## Тесты BLoC

Используют `blocTest` из пакета `bloc_test` для декларативного описания поведения.

### Паттерн

```dart
blocTest<AuthBloc, AuthState>(
  'описание теста',
  build: () {
    // Настройка моков
    when(() => mockRepo.someMethod()).thenAnswer((_) async => ...);
    return AuthBloc(authRepository: mockRepo);
  },
  seed: () => SomeState(...),    // Начальное состояние (опционально)
  act: (bloc) => bloc.add(SomeEvent()),  // Действие
  expect: () => [                // Ожидаемая последовательность состояний
    SomeLoadingState(),
    SomeLoadedState(...),
  ],
);
```

### Что тестируется

**AuthBloc** (6 тестов):
- Проверка сессии — успех, отсутствие сессии, ошибка API
- OAuth — успешная авторизация, ошибка сохранения токенов
- Logout

**WebSocketBloc** (9 тестов):
- `WebSocketConnect` — emits `connecting`, вызывает `connect()`, подписывается на `stateChanges` и `events`
- `WebSocketConnectionChanged` — emits `connected` при `true`, `disconnected` при `false`
- `WebSocketDisconnect` — вызывает `disconnect()`, emits `disconnected`
- `wsEvents` stream — WS-события из `events` транслируются в `wsEvents`
- `sendTyping` — делегирует вызов `WebSocketClient.sendTyping(channelId)`
- `close` — отменяет подписки, события больше не пересылаются

**ConnectivityCubit** (5 тестов):
- Начальное состояние `isConnected = true`
- Подписка на `onConnectivityChanged` — переключение connected/disconnected
- Множественные последовательные изменения состояния
- Отмена подписки при `close()`

**UserStatusCubit** (11 тестов):
- `fetchStatuses` — обновляет statuses при успехе, не emitит при ошибке, ничего не делает для пустого списка, мержит с существующими
- `subscribeToWs` — обновляет статус при `status_change`, игнорирует другие события и события без обязательных полей, перезаписывает статус для того же пользователя
- `requestStatus` — батчит запросы с 100ms debounce, пропускает уже известные статусы

**ChannelsBloc** (4 теста):
- Загрузка каналов — успех, ошибка
- Поиск по имени — фильтрация, сброс фильтра

**PostModel (новые тесты):**
- Парсинг приоритета из `metadata.priority.priority` (urgent, important)
- Пустой приоритет при отсутствии metadata

**ChatBloc** (6 тестов):
- Загрузка сообщений — успех, ошибка
- Отправка сообщения (оптимистичное добавление)
- Удаление сообщения
- Пагинация — блокировка при `isLoadingMore` или `!hasMore`
- Pin/Unpin сообщений — обновление `isPinned` в списке
- ScrollToMessage — загрузка контекста и установка `highlightedPostId`
- ClearHighlight — сброс подсветки
- Использует `MockWsPostParser` для парсинга WS-событий

### Пример

```dart
blocTest<ChatBloc, ChatState>(
  'SendMessage adds post optimistically',
  build: () {
    when(() => mockRepo.createPost(
      channelId: any(named: 'channelId'),
      message: any(named: 'message'),
    )).thenAnswer((_) async => Right(newPost));
    return ChatBloc(postRepository: mockRepo);
  },
  seed: () => ChatState(channelId: 'ch1', posts: existingPosts),
  act: (bloc) => bloc.add(SendMessage(message: 'New')),
  expect: () => [
    isA<ChatState>().having((s) => s.isSending, 'isSending', true),
    isA<ChatState>()
        .having((s) => s.isSending, 'isSending', false)
        .having((s) => s.posts.length, 'posts.length', 3),
  ],
);
```

## Тесты репозиториев

Проверяют взаимодействие между DataSource и Storage с помощью моков.

### Что тестируется

**AuthRepositoryImpl** (7 тестов):
- `getCurrentUser` — успех (сохраняет userId), ошибка (возвращает Failure)
- `saveAuthTokens` — сохранение токена и CSRF
- `logout` — очистка хранилища даже при ошибке сервера
- `hasValidSession` — с токеном, без токена, с невалидным токеном

**PostRepositoryImpl** (32 теста):
- `getChannelPosts` — online (remote + фоновый кеш), offline (из кеша), ServerException + fallback на кеш, ServerException + пустой кеш → `ServerFailure`, CacheException → `CacheFailure`
- `createPost` — online (remote + кеш), offline (сохраняет pending-пост с `pending_*` id), ServerException
- `getPost`, `editPost`, `deletePost`, `getPostThread`, `pinPost`, `unpinPost`, `flagPost`, `unflagPost`, `searchPosts`, `getFlaggedPosts`, `getPinnedPosts`, `getUserThreads` — success/failure пути

**ChannelRepositoryImpl** (16 тестов):
- `getChannelsForUser` — online (remote + enrichment через batch members: msgCount, mentionCount, lastViewedAt, isMuted), batch members fail (каналы без unread info), offline (из кеша), ServerException + fallback, CacheException
- `getChannel`, `viewChannel`, `createDirectChannel`, `muteChannel`, `unmuteChannel` — success/failure

**UserRepositoryImpl** (16 тестов):
- `getUser` — cache-first: возвращает из кеша если есть, иначе из remote; fallback на remote при ошибке кеша
- `getUsersByIds`, `updateUser`, `uploadUserImage`, `autocompleteUsers` (с/без channelId), `getUserStatuses`, `getUserImageUrl`

**SeensRepositoryImpl** (4 теста):
- `getChannelSeens`, `getPostSeens` — success с проверкой полей SeenList, ServerException → ServerFailure

**FileRepositoryImpl** (7 тестов):
- `uploadFiles`, `getFileInfo` — success/failure
- `getFileUrl`, `getThumbnailUrl`, `getPreviewUrl` — проверка формата URL

### Пример

```dart
test('logout clears storage even on server error', () async {
  when(() => mockRemote.logout())
      .thenThrow(ServerException(message: 'error'));
  when(() => mockStorage.clearAll()).thenAnswer((_) async {});

  final result = await repository.logout();

  expect(result.isRight(), true);
  verify(() => mockStorage.clearAll()).called(1);
});
```

## Тесты сервисов

### WsPostParserImpl (9 тестов)

Чистые тесты без моков — вызов `parsePost()` и проверка результата.

- Валидный JSON с полным набором полей → `Post` с правильными значениями
- Минимальный JSON (только обязательные поля) → корректные дефолты
- Невалидный JSON → `null`
- Пустая строка → `null`
- JSON-массив вместо объекта → `null`
- JSON с неизвестными полями → парсит без ошибки
- Forwarded post из permalink embed → `forwardedPostMessage`, `forwardedChannelName`
- Priority metadata → `priority`, `isUrgent`

### SendQueueService (9 тестов)

Тестирует отправку pending-постов при восстановлении сети.

- `start()` — подписывается на `onConnectivityChanged`, вызывает обработку сразу
- Online: получает pending-посты, отправляет каждый через `createPost`, маркирует `markAsSent`
- Offline: не отправляет посты
- Конвертация пустых `rootId`/`fileIds`/`priority` в `null` при отправке
- Передача непустых `rootId`/`fileIds`/`priority` как есть
- Ошибка отправки одного поста → `markAsFailed`, продолжает обработку следующих
- Восстановление сети (connectivity emit `true`) → обрабатывает очередь
- `dispose()` — отменяет подписку, новые события не обрабатываются

## Тесты сетевого слоя

### ApiClient (7 тестов)

Тестирует Dio-интерцепторы через кастомный `DioAdapter` (мок `HttpClientAdapter`).

**AuthInterceptor:**
- Добавляет `Authorization: Bearer <token>` и `X-CSRF-Token` к запросам
- Пропускает заголовки, если токен/CSRF отсутствуют
- Очищает `SecureStorage` при получении 401
- Не очищает storage при других ошибках (403, 500)

**Конфигурация:**
- Правильный `baseUrl` (serverUrl + `/api/v4`)
- `Content-Type: application/json`
- Таймауты из `AppConfig`

## Тесты утилит

### WsEvent
- Парсинг JSON
- Обработка отсутствующих полей
- Приоритет `broadcast.channel_id` над `data.channel_id`

### DateFormatter
- Пустое значение для timestamp = 0
- Форматирование "Today" и "Yesterday"
- Корректное отображение времени

## Соглашения

1. **Имена файлов**: `<unit>_test.dart`
2. **Группировка**: `group()` по классу, вложенные `group()` по методу
3. **Именование тестов**: описание ожидаемого поведения на английском
4. **Моки**: создаются через `class MockX extends Mock implements X {}`
5. **Assertions**: `expect()` с матчерами `isA<T>().having(...)` для сложных проверок

## Интеграционные тесты

Тестируют полные пользовательские сценарии: экран → BLoC → репозиторий (мок) → UI.

### Стратегия мокирования

Мокирование на уровне **абстрактных репозиториев** (domain layer). Все BLoC-и и экраны работают через `AuthRepository`, `ChannelRepository`, `PostRepository` и т.д. — подменяем их через GetIt. WebSocket мокируется через `FakeWebSocketClient` с управляемыми стримами.

### Инфраструктура

**`test_di.dart`** — `initTestDependencies()`:
- Вызывает `sl.reset()` для очистки GetIt
- Создаёт `MockXRepository` для всех 7 репозиториев + фейки для инфраструктуры
- Регистрирует дефолтные стабы (`getUserStatuses`, `getUserImageUrl`, `getUser`, `getFileUrl` и др.)
- Повторяет структуру регистрации из `lib/core/di/injection.dart`
- Возвращает `TestMocks` — контейнер с доступом к мокам для настройки `when()` в тестах

**`test_app.dart`** — хелперы для каждого сценария:
- `createTestApp()` → `TestAppResult(app: App(), mocks: TestMocks)`
- `setupAuthenticatedState(mocks)` — авторизованный пользователь
- `setupUnauthenticatedState(mocks)` — неавторизованный пользователь
- `setupChannelList(mocks)` — список каналов
- `setupChannelPosts(mocks)` — сообщения в канале
- `setupSendMessage(mocks)` — отправка сообщения
- `setupLogin(mocks)` — логин по паролю
- `setupPinMessage(mocks)`, `setupEditMessage(mocks)`, `setupDeleteMessage(mocks)`, `setupThread(mocks)`, `setupPinnedPosts(mocks)`

**`pump_helpers.dart`** — расширения для `WidgetTester`:
- `pumpAndSettle2()` — pump + settle с увеличенным таймаутом
- `pumpN(count)` — pump N кадров (для анимаций, debounce)
- `waitForText(text)` — ожидание появления текста на экране

**`FakeWebSocketClient`** — фейк WebSocket:
- `simulateEvent(WsEvent)` — инъекция WS-события в стрим
- `connect()` — мгновенно переходит в `connected`
- `disconnect()` — мгновенно переходит в `disconnected`

**`ws_event_factory.dart`** — фабрики WS-событий:
- `createPostedEvent()` — новое сообщение
- `createPostEditedEvent()` — редактирование сообщения
- `createPostDeletedEvent()` — удаление сообщения
- `createTypingEvent()` — индикатор набора текста

### Покрытые сценарии

| Сценарий | Файл | Тестов | Описание |
|----------|------|--------|----------|
| Авторизация | `auth_flow_test.dart` | 5 | AuthScreen, логин по паролю, восстановление сессии, ошибка авторизации |
| Список каналов | `channel_list_test.dart` | 4 | Загрузка каналов, навигация в чат, Threads/Drafts, поле поиска |
| Отправка сообщения | `send_message_test.dart` | 2 | createPost вызван, поле ввода очищается |
| Получение через WS | `receive_message_ws_test.dart` | 4 | Новое сообщение, фильтрация по каналу, typing indicator, post_edited |
| Pin/Unpin | `pin_unpin_test.dart` | 3 | Pin через меню, Unpin, индикатор Pinned |
| Поиск каналов | `search_channels_test.dart` | 3 | Фильтрация, очистка, пустой результат |
| Навигация в тред | `thread_navigation_test.dart` | 1 | Tap reply count → ThreadScreen |
| Редактирование/удаление | `edit_delete_message_test.dart` | 3 | Edit, Delete с диалогом, проверка прав на чужие сообщения |

### Runner (без устройства)

`test/integration_runner_test.dart` импортирует все сценарии и вызывает их `main()`:

```dart
import '../integration_test/scenarios/auth_flow_test.dart' as auth_flow;
import '../integration_test/scenarios/channel_list_test.dart' as channel_list;
// ...

void main() {
  auth_flow.main();
  channel_list.main();
  // ...
}
```

Это позволяет запускать интеграционные тесты как обычные widget-тесты без устройства/эмулятора: `flutter test test/integration_runner_test.dart`.

### Паттерн написания нового сценария

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import '../helpers/test_app.dart';
import '../helpers/pump_helpers.dart';

void main() {
  group('My Feature', () {
    testWidgets('описание сценария', (tester) async {
      // 1. Создать приложение с моками
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);

      // 2. Настроить специфичные стабы
      when(() => result.mocks.postRepository.someMethod(...))
          .thenAnswer((_) async => const Right(...));

      // 3. Запустить приложение
      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      // 4. Взаимодействие с UI
      await tester.tap(find.text('Something'));
      await tester.pumpAndSettle();

      // 5. Проверки
      expect(find.text('Expected Result'), findsOneWidget);
      verify(() => result.mocks.postRepository.someMethod(...)).called(1);
    });
  });
}
```

После создания файла — добавить `import` и вызов `main()` в `test/integration_runner_test.dart`.

### Patrol (нативные E2E)

`integration_test/patrol/oauth_browser_test.dart` — тестирование OAuth через системный браузер. Требует:
- Установленный Patrol CLI (`dart pub global activate patrol_cli`)
- Физическое устройство или эмулятор
- Запуск: `patrol test integration_test/patrol/`

## Покрытие по компонентам

| Слой | Компонент | Тесты |
|------|-----------|-------|
| BLoC | AuthBloc, WebSocketBloc, ChannelsBloc, ChatBloc, NotificationBloc, ThreadsBloc | ✅ |
| Cubit | ConnectivityCubit, UserStatusCubit | ✅ |
| Repository | Auth, Post, Channel, User, File, Seens, Notification | ✅ |
| Service | WsPostParserImpl, SendQueueService | ✅ |
| Network | ApiClient (AuthInterceptor, RetryInterceptor) | ✅ |
| Model | User, Channel, Post, FileInfo, UserThread, Draft | ✅ |
| Storage | DraftStorage | ✅ |
| Integration | Auth, Channels, Chat, WS, Pin, Search, Threads, Edit/Delete | ✅ |

## Рекомендации по расширению

При добавлении новой функциональности:

1. **Модель** → тесты `fromJson`, `toJson`, вычисляемые свойства
2. **Репозиторий** → тесты успеха/ошибки для каждого метода; если есть offline-логика — тесты online/offline/fallback
3. **BLoC** → тесты каждого Event с проверкой последовательности State; для WS-подписок — тест с `StreamController`
4. **Сервис** → тесты основной логики, обработки ошибок, подписок
5. **Widget** → `pumpWidget` + проверка ключевых элементов UI (при необходимости)
6. **Пользовательский сценарий** → интеграционный тест в `integration_test/scenarios/` + добавить в runner
