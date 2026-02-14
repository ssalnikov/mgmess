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

### Экранные (создаются/уничтожаются вместе с экраном)

| Блок | Файл | Описание |
|------|------|----------|
| `ChannelsBloc` | `presentation/screens/channels/` | Список каналов, поиск, WS-обновления |
| `ChatBloc` | `presentation/screens/chat/` | Сообщения, отправка, пагинация, typing |
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
AuthAuthenticated(user) // Авторизован
AuthUnauthenticated     // Не авторизован
AuthError(message)      // Ошибка
```

### Взаимодействие
- При `AuthAuthenticated` → WebSocketBloc подключается
- При `AuthUnauthenticated` → WebSocketBloc отключается, GoRouter редиректит на `/auth`

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

### События
```dart
LoadPosts(channelId)          // Загрузить сообщения
LoadMorePosts                 // Загрузить ещё (пагинация при прокрутке вверх)
SendMessage(message, ...)     // Отправить сообщение
DeleteMessage(postId)         // Удалить сообщение
ChatWsEvent(wsEvent)          // WS-событие (new post, edit, delete, typing)
```

### Состояние
```dart
ChatState(
  channelId,
  posts,            // Список сообщений (от новых к старым)
  isLoading,
  isLoadingMore,
  hasMore,          // Есть ли ещё страницы при пагинации
  error,
  typingUsers,      // Set<String> — ID печатающих пользователей
  isSending,
)
```

### Оптимистичная отправка
При `SendMessage` сообщение сразу добавляется в список (до подтверждения сервером). Если оно придёт через WS — дубликат отфильтруется по `id`.

### Пагинация
При достижении конца списка (прокрутка вверх) вызывается `LoadMorePosts`, который загружает следующую порцию через параметр `before` (ID самого старого сообщения).

### Typing индикатор
- WS-событие `typing` добавляет пользователя в `typingUsers`
- Через 5 секунд — автоматически очищается

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

## ConnectivityCubit

Простой Cubit без событий.

```dart
ConnectivityState(isConnected: bool)
```

Подписывается на `connectivity_plus` и эмитит новое состояние при изменении сети.

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
                 ┌────▼───┐    │ wsEvents
                 │Reposit.│    │
                 └────┬───┘    │
                      │        │
                 ┌────▼────────▼───┐
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
    _chatBloc = ChatBloc(postRepository: sl<PostRepository>());
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
