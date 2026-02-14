# WebSocket

## Обзор

WebSocket обеспечивает получение событий в реальном времени: новые сообщения, статусы пользователей, индикатор набора текста, обновления каналов и read receipts (seens). Без WebSocket приложение не узнает о новых событиях до следующего pull-to-refresh.

## Подключение

### URL
```
wss://mm.my.games/api/v4/websocket
```

### Аутентификация

После установки соединения клиент отправляет `authentication_challenge`:

```json
{
  "seq": 1,
  "action": "authentication_challenge",
  "data": {
    "token": "<MMAUTHTOKEN>"
  }
}
```

Сервер отвечает событием `hello`:

```json
{
  "event": "hello",
  "data": {
    "server_version": "9.x.x"
  },
  "seq": 0
}
```

После получения `hello` соединение считается установленным.

## Архитектура

```
                              ┌─────────────────┐
                              │  WebSocketClient │  core/network/
                              │  (connect/       │
                              │   reconnect/     │
                              │   parse events)  │
                              └────────┬─────────┘
                                       │ Stream<WsEvent>
                              ┌────────▼─────────┐
                              │  WebSocketBloc    │  presentation/blocs/
                              │  (connection      │
                              │   management)     │
                              └────────┬─────────┘
                                       │ Stream<WsEvent>
                     ┌─────────────────┼─────────────────┐
                     ▼                 ▼                  ▼
              ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
              │ ChannelsBloc│  │  ChatBloc    │  │ SeensCubit  │
              │ (unread     │  │ (new posts,  │  │ (read       │
              │  counts)    │  │  typing)     │  │  receipts)  │
              └─────────────┘  └─────────────┘  └─────────────┘
```

### WebSocketClient (`core/network/websocket_client.dart`)

Низкоуровневый менеджер соединения:
- Устанавливает WS-соединение
- Отправляет authentication_challenge
- Парсит входящие JSON-сообщения в `WsEvent`
- Реализует автоматический reconnect с exponential backoff
- Предоставляет `Stream<WsEvent>` и `Stream<WsConnectionState>`

### WebSocketBloc (`presentation/blocs/websocket/`)

Управляет жизненным циклом WS на уровне приложения:
- Подключается при `AuthAuthenticated`
- Отключается при `AuthUnauthenticated`
- Транслирует WS-события другим блокам через `wsEvents` stream

## Формат события

```json
{
  "event": "posted",
  "data": {
    "channel_id": "abc123",
    "post": "{\"id\":\"xyz\",\"message\":\"Hello\",\"user_id\":\"u1\",...}",
    "channel_type": "O",
    "sender_name": "johndoe"
  },
  "broadcast": {
    "channel_id": "abc123",
    "team_id": "team1"
  },
  "seq": 42
}
```

**Важно**: поле `data.post` в событиях `posted`, `post_edited`, `post_deleted` — это **JSON-строка** (не объект), требующая дополнительного парсинга через `jsonDecode`.

## Обрабатываемые события

### Сообщения

| Событие | Описание | Обработчик |
|---------|----------|------------|
| `posted` | Новое сообщение | ChatBloc, ChannelsBloc |
| `post_edited` | Сообщение отредактировано | ChatBloc |
| `post_deleted` | Сообщение удалено | ChatBloc |

### Каналы

| Событие | Описание | Обработчик |
|---------|----------|------------|
| `channel_viewed` | Канал помечен как прочитанный | ChannelsBloc |
| `channel_updated` | Канал обновлён (название, заголовок) | ChannelsBloc |
| `direct_added` | Создан новый DM | ChannelsBloc |

### Пользователи

| Событие | Описание | Обработчик |
|---------|----------|------------|
| `typing` | Пользователь печатает | ChatBloc |
| `status_change` | Изменение статуса (online/away/dnd/offline) | — |
| `user_updated` | Профиль обновлён | — |

### Реакции

| Событие | Описание | Обработчик |
|---------|----------|------------|
| `reaction_added` | Добавлена реакция | ChatBloc |
| `reaction_removed` | Убрана реакция | ChatBloc |

### Seens (MyGames)

| Событие | Описание | Обработчик |
|---------|----------|------------|
| `channel_seens_updated` | Обновлены seens канала | SeensCubit |
| `thread_seens_updated` | Обновлены seens треда | SeensCubit |

Кастомное свойство для мобильного маркинга: `WebsocketMessagePropertySeensMark = "its_need_to_mark_seen_for_mobile"`.

### Прочие

| Событие | Описание |
|---------|----------|
| `preferences_changed` | Изменены пользовательские настройки |
| `preferences_deleted` | Удалены настройки |
| `sidebar_category_updated` | Обновлены категории сайдбара |

## Отправка событий

### Индикатор набора текста

```dart
webSocketClient.sendTyping(channelId);
```

Отправляет:
```json
{
  "action": "user_typing",
  "seq": 5,
  "data": {
    "channel_id": "<channelId>"
  }
}
```

## Reconnect

При разрыве соединения применяется **exponential backoff**:

```
Попытка 1: через 1 секунду
Попытка 2: через 2 секунды
Попытка 3: через 4 секунды
Попытка 4: через 8 секунд
Попытка 5: через 16 секунд
Попытка 6+: через 30 секунд (максимум)
```

После успешного подключения (получения `hello`) счётчик попыток сбрасывается.

### Состояния подключения

```dart
enum WsConnectionState { disconnected, connecting, connected }
```

Доступны через `WebSocketBloc.state.connectionState` для отображения статуса в UI (например, баннер "Подключение...").

## Фильтрация событий

`ChatBloc` подписывается только на события текущего канала:

```dart
_wsSub = wsEvents
    .where((e) =>
        e.channelId == state.channelId &&
        (e.event == WsEventType.posted ||
         e.event == WsEventType.postEdited ||
         e.event == WsEventType.postDeleted ||
         e.event == WsEventType.typing))
    .listen((event) => add(ChatWsEvent(wsEvent: event)));
```

`ChannelsBloc` слушает все события для обновления unread counts.
