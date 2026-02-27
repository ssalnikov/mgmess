# State Management

## Обзор

Для управления состоянием используется **BLoC** (Business Logic Component) из пакета `flutter_bloc`. BLoC выбран за:

- **Естественную совместимость с WebSocket** — события WS напрямую мапятся на BLoC Events
- **Строгое разделение** бизнес-логики и UI
- **Масштабируемость** — изоляция доменов (каналы, чат, статусы, seens)
- **Тестируемость** — `bloc_test` для декларативных unit-тестов
- **Прозрачность** — каждый переход состояния явно определён через Event → State

## Паттерн BLoC

```
UI (Widget)
    │ отправляет Event
    ▼
  BLoC
    │ обрабатывает Event
    │ вызывает Repository
    │ emit(новое State)
    ▼
UI (BlocBuilder)
    │ перерисовывается
```

### Cubit vs BLoC

- **BLoC** (Event/State) — для сложной логики с множеством входных событий (ChatBloc, ChannelsBloc)
- **Cubit** (метод → State) — для простых состояний без событий (ConnectivityCubit)

## Список блоков

### Глобальные (живут всё время работы приложения)

| Блок | Файл | Описание |
|------|------|----------|
| `AuthBloc` | `presentation/blocs/auth/` | Управление сессией, OAuth, logout |
| `WebSocketBloc` | `presentation/blocs/websocket/` | WS-соединение, трансляция событий |
| `ConnectivityCubit` | `presentation/blocs/connectivity/` | Состояние сетевого подключения |
| `NotificationBloc` | `presentation/blocs/notification/` | FCM-токен, push-уведомления, фильтрация |
| `UserStatusCubit` | `presentation/blocs/user_status/` | Статусы пользователей (online/away/dnd/offline) |

### Экранные (создаются/уничтожаются вместе с экраном)

| Блок | Файл | Описание |
|------|------|----------|
| `ChannelsBloc` | `presentation/screens/channels/` | Список каналов, поиск, WS-обновления |
| `ChatBloc` | `presentation/screens/chat/` | Сообщения, отправка, пагинация, typing, приоритеты, pin/unpin, scroll-to-message |
| `ThreadBloc` | `presentation/screens/thread/` | Тред (ответы), удаление постов в треде |
| `PinnedMessagesBloc` | `presentation/screens/chat/widgets/` | Закреплённые сообщения канала |
| `SavedMessagesBloc` | `presentation/screens/saved_messages/` | Сохранённые сообщения |
| `MentionsBloc` | `presentation/screens/mentions/` | Упоминания текущего пользователя |

## AuthBloc

Управляет жизненным циклом авторизации.

### События
```dart
AuthCheckSession        // Проверка сессии при запуске
AuthOAuthCompleted      // OAuth callback с токеном
AuthLogoutRequested     // Выход из системы
```

### Состояния
```dart
AuthInitial             // Начальное
AuthLoading             // Загрузка
AuthAuthenticated(user, teamName) // Авторизован (с именем команды)
AuthUnauthenticated     // Не авторизован
AuthError(message)      // Ошибка
```

### Взаимодействие
- При `AuthAuthenticated` → WebSocketBloc подключается, NotificationBloc инициализируется
- При `AuthUnauthenticated` → WebSocketBloc отключается, NotificationBloc делает logout, GoRouter редиректит на `/auth`

## WebSocketBloc

Управляет WS-соединением и транслирует события.

### События
```dart
WebSocketConnect              // Подключиться
WebSocketDisconnect           // Отключиться
WebSocketConnectionChanged    // Изменение состояния соединения
```

### Состояние
```dart
WebSocketState(connectionState: disconnected | connecting | connected)
```

### Трансляция событий
Другие блоки подписываются через `wsBloc.wsEvents`:
```dart
_channelsBloc.subscribeToWs(wsBloc.wsEvents);
_chatBloc.subscribeToWs(wsBloc.wsEvents);
```

## ChannelsBloc

Список каналов с real-time обновлениями.

### События
```dart
LoadChannels(userId, teamId)  // Загрузить каналы
RefreshChannels               // Обновить (pull-to-refresh)
SearchChannels(query)         // Фильтрация по имени
ChannelWsEvent(wsEvent)       // WS-событие (new post, channel viewed)
```

### Состояние
```dart
ChannelsState(
  channels,           // Все каналы
  filteredChannels,   // Отфильтрованные (при поиске)
  isLoading,
  error,
  searchQuery,
)
```

### Обработка WS-событий
- `posted` → увеличивает `totalMsgCount` и `mentionCount` у соответствующего канала
- `channel_viewed` → обнуляет непрочитанные (`msgCount = totalMsgCount`, `mentionCount = 0`)

### Сортировка
Каналы отсортированы по `lastPostAt` (последнее сообщение наверху).

## ChatBloc

Управление сообщениями в конкретном канале.

### Зависимости

`ChatBloc` принимает `PostRepository` и `WsPostParser` — централизованный сервис для парсинга постов из WS-событий (вместо дублирования `PostModel.fromJson` + `jsonDecode` в каждом блоке).

### События
```dart
LoadPosts(channelId)          // Загрузить сообщения
LoadMorePosts                 // Загрузить ещё (пагинация при прокрутке вверх)
SendMessage(message, ..., priority) // Отправить сообщение (опциональный приоритет)
DeleteMessage(postId)         // Удалить сообщение
PinMessage(postId)            // Закрепить сообщение
UnpinMessage(postId)          // Открепить сообщение
ScrollToMessage(postId)       // Прокрутить к сообщению (загрузит контекст если нужно)
ClearHighlight                // Сбросить подсветку целевого сообщения
ChatWsEvent(wsEvent)          // WS-событие (new post, edit, delete, typing)
```

### Состояние
```dart
ChatState(
  channelId,
  posts,              // Список сообщений (от новых к старым)
  isLoading,
  isLoadingMore,
  hasMore,            // Есть ли ещё страницы при пагинации
  error,
  typingUsers,        // Set<String> — ID печатающих пользователей
  isSending,
  highlightedPostId,  // ID подсвечиваемого сообщения (scroll-to-message)
)
```

### Оптимистичная отправка
При `SendMessage` сообщение сразу добавляется в список (до подтверждения сервером). Если оно придёт через WS — дубликат отфильтруется по `id`.

### Пагинация
При достижении конца списка (прокрутка вверх) вызывается `LoadMorePosts`, который загружает следующую порцию через параметр `before` (ID самого старого сообщения).

### Typing индикатор
- WS-событие `typing` добавляет пользователя в `typingUsers`
- Через 5 секунд — автоматически очищается

## PinnedMessagesBloc

Закреплённые сообщения канала. Создаётся при открытии панели закреплённых сообщений.

### События
```dart
LoadPinnedMessages(channelId)       // Загрузить закреплённые
UnpinMessage(postId)                // Открепить сообщение
```

### Состояние
```dart
PinnedMessagesState(posts, isLoading, error)
```

Геттер `groupedByDate` возвращает `Map<String, List<Post>>` для группировки по датам в UI.

## SavedMessagesBloc

### События
```dart
LoadSavedMessages(userId)           // Загрузить сохранённые
UnflagMessage(userId, postId)       // Убрать из сохранённых
```

### Состояние
```dart
SavedMessagesState(posts, isLoading, error)
```

## MentionsBloc

### События
```dart
LoadMentions(teamId, username)      // Поиск @username
```

### Состояние
```dart
MentionsState(posts, isLoading, error)
```

## ThreadBloc

Управление сообщениями в треде (ответах на сообщение). Аналогичен `ChatBloc`, но работает с `posts/{id}/thread` API.

### Зависимости

`ThreadBloc` принимает `PostRepository` и `WsPostParser`.

### События
```dart
LoadThread(postId)            // Загрузить тред
SendThreadReply(message, ...) // Ответить в треде
DeleteThreadPost(postId)      // Удалить пост в треде
ThreadWsEvent(wsEvent)        // WS-событие (новый пост, редактирование, удаление)
```

### Обработка WS-событий

Использует `WsPostParser` для парсинга постов из WS JSON-строк. Обрабатывает `posted`, `post_edited`, `post_deleted` для текущего треда.

## ConnectivityCubit

Простой Cubit без событий.

```dart
ConnectivityState(isConnected: bool)
```

Подписывается на `connectivity_plus` и эмитит новое состояние при изменении сети.

## NotificationBloc

Управление push-уведомлениями через Firebase Cloud Messaging.

### События
```dart
NotificationInit(userId)              // Инициализация при авторизации
NotificationTokenRefreshed(token)     // Обновление FCM-токена
NotificationWsEvent(wsEvent)          // WS-событие (posted → показать уведомление)
NotificationSetActiveChannel(id)      // Пользователь открыл канал → подавление
NotificationClearActiveChannel        // Пользователь вышел из канала
NotificationLogout                    // Выход из системы
```

### Состояния
```dart
NotificationInitial                           // Начальное
NotificationReady(token, enabled)             // Готов к работе
NotificationError(message)                    // Ошибка
```

### Логика обработки WS-событий
При получении `NotificationWsEvent` с типом `posted`:
1. Проверяется, что state = `NotificationReady` и `enabled = true`
2. Проверяется, что канал сообщения ≠ активному каналу
3. Проверяется, что отправитель ≠ текущему пользователю
4. Применяется фильтр (all / mentions_dm / dm_only)
5. Если все проверки пройдены — вызывается `NotificationService.showNotification()`

### Взаимодействие
- `App` подписывает NotificationBloc на `WebSocketBloc.wsEvents`
- При `AuthAuthenticated` → `NotificationInit(userId)` → регистрация FCM-токена на сервере
- При `AuthUnauthenticated` → `NotificationLogout` → снятие device_id с сессии

## UserStatusCubit

Управление статусами пользователей (online / away / dnd / offline) с батчированием запросов.

### Состояние
```dart
UserStatusState(statuses: Map<String, String>)  // userId -> status
```

### Логика
- `subscribeToWs(wsEvents)` — слушает WS-события `status_change`, обновляет статус пользователя
- `fetchStatuses(userIds)` — загружает статусы через `UserRepository.getUserStatuses()`
- `requestStatus(userId)` — ленивый запрос: если статус не в кеше, добавляет в очередь. Через 100ms батч запрос отправляется на сервер
- Используется в `UserAvatar` — запрашивает статус при рендеринге, показывает цветной индикатор

## Поток данных

```
                  ┌─────────────────┐
                  │   Mattermost    │
                  │    Server       │
                  └───┬─────────┬───┘
                      │ REST    │ WS
                 ┌────▼───┐ ┌──▼───────┐
                 │ApiClient│ │WebSocket │
                 │ (Dio)   │ │Client    │
                 └────┬───┘ └──┬───────┘
                      │        │
                 ┌────▼───┐ ┌──▼───────┐
                 │DataSrc  │ │WebSocket │
                 │(Remote) │ │Bloc      │
                 └────┬───┘ └──┬───────┘
                      │        │
              ┌───────▼───┐    │ wsEvents
              │ Repository │    │
              │ (online →  │    │
              │  remote +  │    │
              │  cache;    │    │
              │  offline → │    │
              │  local DB) │    │
              └───┬───┬───┘    │
                  │   │        │
            ┌─────┘   └──────┐ │
            ▼                ▼ │
       ┌────────┐   ┌────────┐│
       │DataSrc │   │SendQ.  ││
       │(Local) │   │Service ││
       │ Drift  │   │(pending││
       └────────┘   │ posts) ││
                    └────────┘│
                      │       │
                 ┌────▼───────▼───┐
                 │    Feature BLoC  │
                 │ (Channels, Chat) │
                 └────────┬────────┘
                          │ State
                     ┌────▼────┐
                     │   UI    │
                     │(Screen) │
                     └─────────┘
```

## Предоставление блоков

Глобальные блоки регистрируются в `App` через `MultiBlocProvider`:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider.value(value: _authBloc),
    BlocProvider.value(value: _wsBloc),
    BlocProvider.value(value: _connectivityCubit),
    BlocProvider.value(value: _notificationBloc),
  ],
  child: MaterialApp.router(...),
)
```

Экранные блоки создаются в `State.initState()` и предоставляются через `BlocProvider.value`:

```dart
class _ChatScreenState extends State<ChatScreen> {
  late final ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc(
      postRepository: sl<PostRepository>(),
      wsPostParser: sl<WsPostParser>(),
    );
    _chatBloc.add(LoadPosts(channelId: widget.channelId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: ...
    );
  }
}
```
