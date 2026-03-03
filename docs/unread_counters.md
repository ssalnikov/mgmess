# Счётчики непрочитанных сообщений и информеры

Документ описывает архитектуру обновления счётчиков непрочитанных сообщений в каналах, чатах и тредах. Охватывает полный путь данных: от WebSocket-события сервера до отображения в UI.

## Содержание

1. [Общая архитектура](#1-общая-архитектура)
2. [Каналы: счётчики в списке каналов](#2-каналы-счётчики-в-списке-каналов)
3. [Чат: индикатор новых сообщений внутри канала](#3-чат-индикатор-новых-сообщений-внутри-канала)
4. [Треды: счётчики непрочитанных ответов](#4-треды-счётчики-непрочитанных-ответов)
5. [WebSocket-события: полный поток данных](#5-websocket-события-полный-поток-данных)
6. [Badge приложения](#6-badge-приложения)
7. [Диаграмма архитектуры](#7-диаграмма-архитектуры)

---

## 1. Общая архитектура

Система счётчиков непрочитанного построена на трёх механизмах:

1. **Начальная загрузка** — при открытии списка каналов/тредов данные загружаются с сервера (API), включая поля `msg_count`, `mention_count`, `unread_replies` из данных членства пользователя.
2. **Real-time обновление через WebSocket** — при получении WS-событий (`posted`, `channel_viewed`) BLoC-и обновляют локальное состояние без повторного обращения к API.
3. **Оптимистичное обновление** — при пометке канала как прочитанного UI обновляется мгновенно, API-запрос отправляется в фоне.

### Ключевые BLoC-и

| BLoC | Скоуп | WS-события | Ответственность |
|------|-------|------------|-----------------|
| `ChannelsBloc` | Экран каналов | `posted`, `channel_viewed` | Счётчики в списке каналов |
| `ChatBloc` | Экран чата | `posted`, `post_edited`, `post_deleted`, `typing`, `reaction_*` | Сообщения, разделитель «New messages» |
| `ThreadBloc` | Экран треда | `posted`, `post_edited`, `post_deleted`, `reaction_*` | Сообщения внутри конкретного треда |
| `ThreadsBloc` | Экран списка тредов | — (не подписан) | Загрузка и отображение списка тредов |
| `NotificationBloc` | Глобальный | `posted` | Локальные push-уведомления |

---

## 2. Каналы: счётчики в списке каналов

### 2.1. Сущность Channel

**Файл:** `lib/domain/entities/channel.dart`

Ключевые поля для отслеживания непрочитанного:

```dart
class Channel extends Equatable {
  final int totalMsgCount;   // Всего сообщений в канале (глобальный счётчик)
  final int msgCount;         // Сообщений, которые текущий пользователь видел
  final int mentionCount;     // Непрочитанные упоминания текущего пользователя
  final int lastPostAt;       // Timestamp последнего сообщения (для сортировки)
  final int lastViewedAt;     // Timestamp последнего просмотра канала
  final bool isMuted;         // Канал отключен (notify_props.mark_unread == 'mention')

  // Вычисляемые свойства
  int get unreadCount => totalMsgCount - msgCount;
  bool get hasUnread => unreadCount > 0;
  bool get hasMention => mentionCount > 0;
}
```

**Формула:** `unreadCount = totalMsgCount - msgCount`. Сервер хранит глобальный `totalMsgCount` канала и персональный `msgCount` пользователя (из таблицы `ChannelMembers`).

### 2.2. Загрузка данных с сервера

**Файл:** `lib/data/repositories/channel_repository_impl.dart`

При загрузке каналов выполняются два параллельных API-запроса:

1. `GET /users/{userId}/teams/{teamId}/channels` — базовые данные каналов
2. `GET /users/{userId}/teams/{teamId}/channels/members` — данные членства (`msg_count`, `mention_count`, `last_viewed_at`, `notify_props`)

Результаты обогащаются (enrichment): каждый канал получает данные из своего объекта членства.

```dart
final enriched = channels.map((channel) {
  final member = membersByChannelId[channel.id];
  if (member == null) return channel;
  return channel.copyWith(
    msgCount: member['msg_count'],
    mentionCount: member['mention_count'],
    lastViewedAt: member['last_viewed_at'],
    isMuted: member['notify_props']?['mark_unread'] == 'mention',
  );
}).toList();
```

При офлайн-режиме данные берутся из локальной БД (Drift/SQLite).

### 2.3. Обновление при новом сообщении (WS: `posted`)

**Файл:** `lib/presentation/screens/channels/channels_bloc.dart`, метод `_handleNewPost`

Когда приходит WS-событие `posted`:

```
WS "posted" → ChannelsBloc._handleNewPost():
  1. Находит канал по channelId из broadcast
  2. totalMsgCount += 1
  3. Если mentions содержит userId → mentionCount += 1
  4. lastPostAt = createAt из JSON-строки поста
  5. Пересортировка каналов по lastPostAt (desc)
  6. emit() → UI перерисовывается
  7. Обновление badge приложения
```

Поле `msgCount` **не** изменяется — оно обновляется только при просмотре канала. Поэтому `unreadCount` (= `totalMsgCount - msgCount`) автоматически увеличивается на 1.

**Обработка упоминаний:** WS-событие `posted` содержит поле `data.mentions` — JSON-строка с массивом ID упомянутых пользователей. Если текущий `userId` присутствует, `mentionCount` увеличивается.

### 2.4. Пометка канала как прочитанного

**Файл:** `lib/presentation/screens/channels/channels_bloc.dart`, метод `_onMarkChannelAsRead`

Срабатывает при нажатии на канал в списке (`onTap` в `_ChannelListTile`):

```
Пользователь нажимает на канал → MarkChannelAsRead event:
  1. Оптимистичное обновление: msgCount = totalMsgCount, mentionCount = 0
  2. emit() → индикатор исчезает мгновенно
  3. Фоновый API-запрос: POST /channels/members/{userId}/view
     body: {"channel_id": channelId}
  4. Сервер обновляет last_viewed_at и msg_count в ChannelMembers
  5. Сервер рассылает WS-событие "channel_viewed" (подтверждение)
```

### 2.5. Обработка WS-события `channel_viewed`

**Файл:** `lib/presentation/screens/channels/channels_bloc.dart`, метод `_handleChannelViewed`

Дублирующий механизм: если канал был открыт на другом устройстве, WS-событие `channel_viewed` придёт и сбросит счётчики локально:

```dart
void _handleChannelViewed(WsEvent wsEvent, Emitter<ChannelsState> emit) {
  // msgCount = totalMsgCount → unreadCount = 0
  // mentionCount = 0
}
```

### 2.6. UI: отображение индикаторов

**Файл:** `lib/presentation/screens/channels/channels_screen.dart`, виджет `_ChannelListTile`

Приоритет отображения trailing-виджета:

| Приоритет | Условие | Отображение |
|-----------|---------|-------------|
| 1 | `channel.isMuted` | Иконка `Icons.notifications_off` (серая) |
| 2 | `channel.hasMention` | Красный badge с числом `mentionCount` |
| 3 | `channel.hasUnread` | Маленькая цветная точка (accent) |
| 4 | Всё прочитано | Ничего |

Дополнительно: при `hasUnread && !isMuted` имя канала отображается **жирным шрифтом** (`FontWeight.bold`).

---

## 3. Чат: индикатор новых сообщений внутри канала

### 3.1. Состояние ChatBloc

**Файл:** `lib/presentation/screens/chat/chat_bloc.dart`

Поля состояния, связанные с отслеживанием непрочитанного:

```dart
class ChatState extends Equatable {
  final int lastViewedAt;         // Timestamp последнего просмотра (передаётся из ChannelsScreen)
  final int newMessagesCount;     // Счётчик новых сообщений (для индикатора)
  final String? firstUnreadId;    // ID первого непрочитанного поста (для разделителя)
  final String? highlightedPostId; // ID поста для выделения (scroll-to-message)
}
```

### 3.2. Определение первого непрочитанного сообщения

При загрузке постов (`_onLoadPosts`) ChatBloc определяет `firstUnreadId`:

```
LoadPosts → getChannelPosts(channelId):
  1. Посты отсортированы от новых к старым
  2. Обход от конца к началу (от старых к новым)
  3. Первый пост с createAt > lastViewedAt → его ID = firstUnreadId
```

`lastViewedAt` передаётся из `ChannelsScreen` через навигационные параметры (`extra['lastViewedAt']`) при открытии чата.

### 3.3. Разделитель «New messages»

**Файл:** `lib/presentation/screens/chat/chat_screen.dart`

В `ListView.builder` (с `reverse: true`) перед постом с `id == firstUnreadId` вставляется разделитель:

```
╔══════════════════════════════════════╗
║  --- New messages ---                ║
║  (акцентный цвет, Divider + текст)  ║
╚══════════════════════════════════════╝
```

Разделитель отображается, пока пользователь не проскролит вниз (к новым сообщениям), после чего вызывается `ClearNewMessages` и `firstUnreadId` обнуляется.

### 3.4. Индикатор «N new messages» (плавающая кнопка)

**Файл:** `lib/presentation/screens/chat/widgets/new_messages_indicator.dart`

Плавающий индикатор внизу экрана чата показывается при выполнении обоих условий:

1. `_isUserScrolledUp == true` — пользователь проскролил вверх (> 200px)
2. `state.newMessagesCount > 0` — есть новые сообщения

```
┌────────────────────────────────┐
│   ↓  3 new messages            │   ← Нажатие → скролл вниз + ClearNewMessages
└────────────────────────────────┘
```

При нажатии или скролле вниз (< 200px) вызывается `ClearNewMessages`, который обнуляет `newMessagesCount` и `firstUnreadId`.

### 3.5. Обработка новых WS-сообщений в ChatBloc

**Файл:** `lib/presentation/screens/chat/chat_bloc.dart`, метод `_handleNewPost`

```
WS "posted" (для текущего channelId) → ChatBloc._handleNewPost():
  1. Парсинг: data.post (JSON-строка!) → WsPostParser.parsePost() → Post
  2. Если post.isReply → обновить replyCount у корневого поста, не добавлять в список
  3. Если дубликат (уже есть в списке) → игнорировать
  4. Иначе → добавить в начало списка: [newPost, ...state.posts]
```

**Важно:** Поле `data.post` в WS-событиях — это **JSON-строка**, не объект. Требуется `jsonDecode` через `WsPostParser`.

### 3.6. Жизненный цикл просмотра чата

```
1. Пользователь нажимает на канал в ChannelsScreen
   → MarkChannelAsRead (оптимистичное обнуление счётчиков)
   → viewChannel() API (фоновый запрос)
   → Навигация на ChatScreen с extra: {lastViewedAt: channel.lastViewedAt}

2. ChatScreen.initState()
   → SetLastViewedAt(lastViewedAt) → сохраняем в ChatBloc
   → LoadPosts(channelId) → загружаем посты + определяем firstUnreadId
   → subscribeToWs(wsBloc.wsEvents) → подписка на WS

3. Пользователь читает сообщения
   → _scrollController отслеживает позицию
   → pixels > 200 → _isUserScrolledUp = true
   → pixels ≤ 200 → _isUserScrolledUp = false → ClearNewMessages

4. Новые WS-сообщения
   → _handleNewPost() → пост добавляется в начало списка
   → Если пользователь скролил вверх → индикатор видим

5. Пользователь покидает чат
   → ChatBloc.close() → отписка от WS
```

### 3.7. Scroll-to-message с подсветкой

Используется при навигации «Показать в канале» из треда:

```
ScrollToMessage(postId) → ChatBloc:
  1. Если пост уже в списке → emit(highlightedPostId: postId)
  2. Иначе → загрузить посты вокруг целевого через API (before/after)
  3. UI скролит к посту + жёлтая подсветка (TweenAnimationBuilder)
  4. Через 3 секунды → ClearHighlight → подсветка исчезает
```

---

## 4. Треды: счётчики непрочитанных ответов

### 4.1. Сущность UserThread

**Файл:** `lib/domain/entities/user_thread.dart`

```dart
class UserThread extends Equatable {
  final int replyCount;        // Общее количество ответов
  final int lastReplyAt;       // Timestamp последнего ответа
  final int lastViewedAt;      // Последний просмотр пользователем
  final int unreadReplies;     // Непрочитанные ответы
  final int unreadMentions;    // Непрочитанные упоминания
  final Post post;             // Корневой пост треда

  bool get hasUnread => unreadReplies > 0;
}
```

В отличие от каналов, для тредов сервер возвращает готовые поля `unread_replies` и `unread_mentions` — клиенту не нужно вычислять разницу.

### 4.2. Загрузка тредов

**Файл:** `lib/data/datasources/remote/post_remote_datasource.dart`

```
GET /api/v4/users/{userId}/teams/{teamId}/threads?per_page=25&extended=true
```

Ответ содержит массив `threads`, каждый элемент включает `unread_replies` и `unread_mentions`.

**Важно:** Тредам **не** доступен офлайн-кеш — `getUserThreads` работает только с remote data source.

### 4.3. ThreadsBloc — загрузка без WS

**Файл:** `lib/presentation/screens/threads/threads_bloc.dart`

`ThreadsBloc` **не подписан** на WebSocket-события. Счётчики `unreadReplies` обновляются только при:

- Первой загрузке (`LoadThreads`)
- Pull-to-refresh
- Пагинации (`LoadMoreThreads`)

Это означает, что если пользователь находится на экране списка тредов и получает новый ответ, счётчик **не обновится** автоматически — нужен refresh.

### 4.4. ThreadBloc — real-time внутри треда

**Файл:** `lib/presentation/screens/thread/thread_bloc.dart`

`ThreadBloc` (для экрана конкретного треда) **подписан** на WS и обрабатывает:

- `posted` — добавляет новый ответ (если `rootId == state.rootPostId`)
- `post_edited` — обновляет отредактированный пост
- `post_deleted` — удаляет пост из списка
- `reaction_added` / `reaction_removed` — обновляет реакции

### 4.5. UI: отображение в списке тредов

**Файл:** `lib/presentation/screens/threads/threads_screen.dart`

В `_ThreadTile` trailing-виджет:

| Условие | Отображение |
|---------|-------------|
| `thread.hasUnread` | Красный badge с числом `unreadReplies` |
| Всё прочитано | Ничего |

### 4.6. Ограничения текущей реализации

1. **Нет real-time обновления списка тредов** — ThreadsBloc не подписан на WS
2. **Нет офлайн-режима** — только remote data source
3. **Нет автоматического сброса счётчика** — при открытии треда `unreadReplies` не обнуляется в списке тредов
4. WS-событие `thread_seens_updated` определено в `WsEventType`, но не обрабатывается ни одним BLoC-ом

---

## 5. WebSocket-события: полный поток данных

### 5.1. Путь WS-события от сервера до UI

```
Mattermost Server
  │ WS JSON-сообщение
  ▼
WebSocketClient (lib/core/network/websocket_client.dart)
  │ jsonDecode → WsEvent
  │ _eventController.add(event)
  ▼
WebSocketBloc (lib/presentation/blocs/websocket/websocket_bloc.dart)
  │ _wsEventController.add(wsEvent)
  │ Broadcast stream: wsEvents
  ├──────────────────┬───────────────────┬──────────────────┐
  ▼                  ▼                   ▼                  ▼
ChannelsBloc      ChatBloc          ThreadBloc       NotificationBloc
(subscribeToWs)   (subscribeToWs)   (subscribeToWs)  (NotificationWsEvent)
  │                  │                   │                  │
  ▼                  ▼                   ▼                  ▼
emit(state)       emit(state)        emit(state)      showNotification()
  │                  │                   │
  ▼                  ▼                   ▼
BlocBuilder →     BlocBuilder →      BlocBuilder →
UI обновление     UI обновление      UI обновление
```

### 5.2. Формат WS-событий

Все WS-события имеют единую структуру:

```dart
class WsEvent {
  final String event;                    // Тип события
  final Map<String, dynamic> data;       // Данные (пост, реакция и т.д.)
  final Map<String, dynamic> broadcast;  // channel_id, user_id, team_id
  final int seq;                         // Порядковый номер
}
```

### 5.3. Типы событий, влияющие на счётчики

| Событие | Влияние | Обработчик |
|---------|---------|------------|
| `posted` | +1 к `totalMsgCount` канала, +1 к `mentionCount` (если упомянут), новый пост в ChatBloc | ChannelsBloc, ChatBloc, ThreadBloc, NotificationBloc |
| `channel_viewed` | Сброс `unreadCount` и `mentionCount` канала | ChannelsBloc |
| `post_edited` | Обновление текста поста в ChatBloc/ThreadBloc | ChatBloc, ThreadBloc |
| `post_deleted` | Удаление поста, -1 к `replyCount` если это ответ | ChatBloc, ThreadBloc |
| `typing` | Индикатор «печатает…» | ChatBloc |
| `reaction_added` / `reaction_removed` | Обновление реакций | ChatBloc, ThreadBloc |
| `status_change` | Обновление статуса пользователя (online/away/dnd/offline) | UserStatusCubit |
| `channel_seens_updated` | Обновление seens (кастомное расширение MyGames) | SeensCubit |
| `thread_seens_updated` | Обновление seens треда (определено, но не обрабатывается) | — |

### 5.4. Подписка экранных BLoC-ов на WS

Экранные BLoC-и подписываются на `WebSocketBloc.wsEvents` в `initState()` экрана:

```dart
// ChannelsScreen
void _subscribeToWs() {
  final wsBloc = context.read<WebSocketBloc>();
  _channelsBloc.subscribeToWs(wsBloc.wsEvents);
}

// ChatScreen
void initState() {
  // ...
  final wsBloc = context.read<WebSocketBloc>();
  _chatBloc.subscribeToWs(wsBloc.wsEvents);
}
```

**ChatBloc** дополнительно фильтрует события по `channelId`, чтобы обрабатывать только сообщения текущего канала:

```dart
void subscribeToWs(Stream<WsEvent> wsEvents) {
  _wsSub = wsEvents
      .where((e) => e.channelId == state.channelId && ...)
      .listen((event) => add(ChatWsEvent(wsEvent: event)));
}
```

### 5.5. Парсинг JSON-строк в WS-событиях

Поля `data.post` и `data.reaction` в WS-событиях — **JSON-строки**, не объекты:

```json
{
  "event": "posted",
  "data": {
    "post": "{\"id\":\"p1\",\"message\":\"Hello\",...}",
    "mentions": "[\"user1\",\"user2\"]"
  }
}
```

Парсинг выполняется через `WsPostParser` (`lib/data/services/ws_post_parser_impl.dart`):

```dart
Post? parsePost(String jsonString) {
  final json = jsonDecode(jsonString);
  return PostModel.fromJson(json);
}
```

---

## 6. Badge приложения

**Файл:** `lib/presentation/screens/channels/channels_bloc.dart`, метод `_updateAppBadge`

Badge на иконке приложения (красный кружок с цифрой) показывает суммарное количество непрочитанных **упоминаний** (не всех сообщений) по всем немьютированным каналам:

```dart
Future<void> _updateAppBadge(List<Channel> channels) async {
  int totalMentions = 0;
  for (final c in channels) {
    if (!c.isMuted) {
      totalMentions += c.mentionCount;
    }
  }
  await AppBadgePlus.updateBadge(totalMentions);
}
```

Вызывается при каждом обновлении счётчиков: новый пост, просмотр канала, начальная загрузка.

---

## 7. Диаграмма архитектуры

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Mattermost Server                            │
│              wss://mm.my.games/api/v4/websocket                    │
└─────────────┬───────────────────────────────────────────────────────┘
              │ WS-события (JSON)
              ▼
┌─────────────────────────────────────────────────┐
│           WebSocketClient                        │
│  (lib/core/network/websocket_client.dart)        │
│  - Подключение + authentication_challenge        │
│  - Reconnect с exponential backoff               │
│  - Stream<WsEvent> events                        │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│           WebSocketBloc (глобальный)             │
│  (lib/presentation/blocs/websocket/)             │
│  - Управление жизненным циклом WS               │
│  - Broadcast: Stream<WsEvent> wsEvents          │
└───┬─────────┬──────────┬───────────┬────────────┘
    │         │          │           │
    ▼         ▼          ▼           ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌──────────────┐
│Channels│ │ Chat   │ │Thread  │ │Notification  │
│Bloc    │ │ Bloc   │ │Bloc    │ │Bloc          │
│        │ │        │ │        │ │              │
│posted: │ │posted: │ │posted: │ │posted:       │
│+total  │ │+пост в │ │+ответ  │ │показать      │
│+mention│ │список  │ │в тред  │ │уведомление   │
│        │ │        │ │        │ │              │
│channel_│ │typing: │ │edited: │ │Подавление:   │
│viewed: │ │индикат.│ │обновить│ │- свой пост   │
│обнулить│ │        │ │        │ │- активный    │
│счётчики│ │edited: │ │deleted:│ │  канал       │
│        │ │обновить│ │удалить │ │- мьют        │
└───┬────┘ └───┬────┘ └───┬────┘ └──────────────┘
    │          │          │
    ▼          ▼          ▼
┌─────────────────────────────────────────────────┐
│              UI (BlocBuilder)                    │
│                                                  │
│  ChannelsScreen:                                 │
│  ┌──────────────────────────────────────────┐   │
│  │ General           ●  (unread dot)        │   │
│  │ Flutter Dev      [3] (mention badge)     │   │
│  │ Random                (всё прочитано)    │   │
│  │ Design           🔕  (muted)            │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  ChatScreen:                                     │
│  ┌──────────────────────────────────────────┐   │
│  │ Старые сообщения…                        │   │
│  │ ──────── New messages ────────           │   │
│  │ Новое сообщение от Алисы                 │   │
│  │ Новое сообщение от Боба                  │   │
│  │                                          │   │
│  │     [ ↓ 2 new messages ]  (floating)     │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  ThreadsScreen:                                  │
│  ┌──────────────────────────────────────────┐   │
│  │ Thread 1  · 5 replies     [2] (unread)   │   │
│  │ Thread 2  · 3 replies         (read)     │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

---

## Сценарии обновления

### Сценарий 1: Новое сообщение в канале (пользователь на экране каналов)

```
1. Сервер → WS "posted" {channel_id: "ch-001", post: "{...}", mentions: "[u1]"}
2. WebSocketBloc → broadcast wsEvents
3. ChannelsBloc._handleNewPost():
   - ch-001.totalMsgCount += 1
   - ch-001.mentionCount += 1 (если u1 = текущий пользователь)
   - ch-001.lastPostAt = post.create_at
   - Пересортировка каналов
   - emit() → UI обновляется
4. NotificationBloc → showNotification("General", "alice: Hello!")
5. Badge приложения обновляется
```

### Сценарий 2: Пользователь открывает канал

```
1. onTap → MarkChannelAsRead(channelId: "ch-001")
2. ChannelsBloc:
   - msgCount = totalMsgCount → unreadCount = 0
   - mentionCount = 0
   - emit() → индикатор исчезает мгновенно
3. Фоново: POST /channels/members/{userId}/view {channel_id: "ch-001"}
4. Сервер → WS "channel_viewed" (подтверждение)
5. Навигация → ChatScreen(channelId, lastViewedAt)
6. ChatBloc → LoadPosts → определяет firstUnreadId
7. UI показывает разделитель "New messages"
```

### Сценарий 3: Новое сообщение в открытом чате (пользователь скролил вверх)

```
1. WS "posted" → ChatBloc._handleNewPost()
2. Пост добавляется в начало списка (reverse: true)
3. Пользователь скролил вверх (_isUserScrolledUp = true)
4. Плавающий индикатор "1 new message" появляется
5. Пользователь нажимает → _scrollToBottom() + ClearNewMessages
6. Индикатор исчезает, firstUnreadId обнуляется
```

### Сценарий 4: Просмотр канала на другом устройстве

```
1. Другое устройство → POST /channels/members/{userId}/view
2. Сервер → WS "channel_viewed" {channel_id: "ch-001"} → все устройства
3. ChannelsBloc._handleChannelViewed():
   - msgCount = totalMsgCount
   - mentionCount = 0
   - emit() → индикатор исчезает
4. Badge обновляется
```

---

## Ключевые файлы

| Файл | Назначение |
|------|-----------|
| `lib/domain/entities/channel.dart` | Сущность Channel с `unreadCount`, `hasUnread`, `hasMention` |
| `lib/domain/entities/user_thread.dart` | Сущность UserThread с `unreadReplies`, `hasUnread` |
| `lib/presentation/screens/channels/channels_bloc.dart` | Управление счётчиками каналов, WS-обработка |
| `lib/presentation/screens/chat/chat_bloc.dart` | Управление сообщениями, `firstUnreadId`, `newMessagesCount` |
| `lib/presentation/screens/chat/widgets/new_messages_indicator.dart` | Плавающий индикатор новых сообщений |
| `lib/presentation/screens/threads/threads_bloc.dart` | Загрузка тредов с `unreadReplies` |
| `lib/presentation/screens/thread/thread_bloc.dart` | Real-time обновление внутри треда |
| `lib/presentation/blocs/websocket/websocket_bloc.dart` | Broadcast WS-событий |
| `lib/core/network/websocket_client.dart` | WS-соединение, парсинг событий |
| `lib/core/network/websocket_events.dart` | Типы WS-событий (`WsEventType`) |
| `lib/data/services/ws_post_parser_impl.dart` | Парсинг JSON-строк постов из WS |
| `lib/data/repositories/channel_repository_impl.dart` | Загрузка каналов с enrichment данных членства |
| `lib/data/datasources/remote/channel_remote_datasource.dart` | API: viewChannel, getChannelMembers |
