# Анализ счётчиков непрочитанных сообщений в Mattermost

Анализ выполнен на основе исходного кода веб-проекта Mattermost (`mattermost/mattermost`).

## 1. Структуры данных (серверные таблицы)

### Таблица `Channels`

Хранит глобальный счётчик всех сообщений канала.

```go
// server/public/model/channel.go:75
type Channel struct {
    TotalMsgCount     int64  `json:"total_msg_count"`      // общее кол-во сообщений
    TotalMsgCountRoot int64  `json:"total_msg_count_root"`  // только root-посты (без replies)
    LastPostAt        int64  `json:"last_post_at"`
    // ...
}
```

### Таблица `ChannelMembers`

Хранит «курсор» каждого пользователя — сколько сообщений он уже видел.

```go
// server/public/model/channel_member.go:54
type ChannelMember struct {
    ChannelId          string `json:"channel_id"`
    UserId             string `json:"user_id"`
    LastViewedAt       int64  `json:"last_viewed_at"`       // timestamp последнего просмотра
    MsgCount           int64  `json:"msg_count"`            // кол-во сообщений на момент последнего прочтения
    MsgCountRoot       int64  `json:"msg_count_root"`       // то же для root-постов
    MentionCount       int64  `json:"mention_count"`        // непрочитанные @mentions
    MentionCountRoot   int64  `json:"mention_count_root"`   // @mentions в root-постах
    UrgentMentionCount int64  `json:"urgent_mention_count"` // срочные @mentions
    NotifyProps        StringMap `json:"notify_props"`
    LastSeenAt         int64  `json:"last_seen_at"`         // кастомное поле MyGames (seens)
    // ...
}
```

### Структура `ChannelUnread` (результат запроса)

```go
// server/public/model/channel_member.go:30
type ChannelUnread struct {
    TeamId             string `json:"team_id"`
    ChannelId          string `json:"channel_id"`
    MsgCount           int64  `json:"msg_count"`             // вычисленное кол-во непрочитанных
    MentionCount       int64  `json:"mention_count"`
    MentionCountRoot   int64  `json:"mention_count_root"`
    UrgentMentionCount int64  `json:"urgent_mention_count"`
    MsgCountRoot       int64  `json:"msg_count_root"`
    NotifyProps        StringMap `json:"-"`
}
```

## 2. Формула расчёта непрочитанных

**Непрочитанные = `Channels.TotalMsgCount` - `ChannelMembers.MsgCount`**

SQL-запрос из `channel_store.go:879-891`:

```sql
SELECT
    Channels.TeamId TeamId,
    Channels.Id ChannelId,
    (Channels.TotalMsgCount - ChannelMembers.MsgCount) MsgCount,
    (Channels.TotalMsgCountRoot - ChannelMembers.MsgCountRoot) MsgCountRoot,
    ChannelMembers.MentionCount MentionCount,
    ChannelMembers.MentionCountRoot MentionCountRoot,
    COALESCE(ChannelMembers.UrgentMentionCount, 0) UrgentMentionCount,
    ChannelMembers.NotifyProps NotifyProps
FROM
    Channels, ChannelMembers
WHERE
    Id = ChannelId
    AND Id = ?
    AND UserId = ?
    AND DeleteAt = 0
```

Эта формула используется в трёх store-методах:
- `GetChannelUnread()` — `channel_store.go:879` (один канал)
- `GetChannelUnreadsForTeam()` — `team_store.go:1168` (все каналы команды)
- `GetChannelUnreadsForAllTeams()` — `team_store.go:1146` (все каналы всех команд)

На клиенте — та же формула (`channel_utils.ts:371-404`):

```typescript
export function calculateUnreadCount(
    messageCount: ChannelMessageCount | undefined,
    member: ChannelMembership | undefined,
    crtEnabled: boolean,
): {showUnread: boolean; mentions: number; messages: number; hasUrgent: boolean} {
    if (!member || !messageCount) {
        return { showUnread: false, hasUrgent: false, mentions: 0, messages: 0 };
    }

    let messages, mentions, hasUrgent = false;
    if (crtEnabled) {
        messages = messageCount.root - member.msg_count_root;  // только root-посты
        mentions = member.mention_count_root;
    } else {
        mentions = member.mention_count;
        messages = messageCount.total - member.msg_count;       // все посты
    }
    if (member.urgent_mention_count) hasUrgent = true;

    return {
        showUnread: mentions > 0 || (!isChannelMuted(member) && messages > 0),
        messages,
        mentions,
        hasUrgent,
    };
}
```

## 3. Что происходит при создании нового поста

### Сервер

**Инкремент общего счётчика** (`post_store.go:251-255`):

```sql
UPDATE Channels SET
    LastPostAt = GREATEST(:lastpostat, LastPostAt),
    LastRootPostAt = GREATEST(:lastrootpostat, LastRootPostAt),
    TotalMsgCount = TotalMsgCount + :count,
    TotalMsgCountRoot = TotalMsgCountRoot + :countroot
WHERE Id = :channelid
```

`MsgCount` в `ChannelMembers` для других пользователей НЕ меняется — разница автоматически растёт.

**Инкремент mentions** (`channel_store.go:2887-2910`):

```sql
UPDATE ChannelMembers SET
    MentionCount = MentionCount + 1,
    MentionCountRoot = MentionCountRoot + ? -- (1 если root, 0 если reply)
    UrgentMentionCount = UrgentMentionCount + ?
WHERE UserId IN (...) AND ChannelId = ?
```

### Клиент (webapp, Redux)

При получении WS-события `posted` срабатывает цепочка:
`handleNewPostEvent` -> `completePostReceive` -> `setChannelReadAndViewed`

**Если пользователь НЕ смотрит канал** — `actionsToMarkChannelAsUnread()` (`channels.ts:1292`):
- `INCREMENT_TOTAL_MSG_COUNT` — увеличивает `messageCounts[channelId].total` на 1
- `INCREMENT_UNREAD_MSG_COUNT` — увеличивает `msg_count` в membership (только для каналов с `mark_unread=mention`)
- `INCREMENT_UNREAD_MENTION_COUNT` — если текущий пользователь в списке упомянутых

**Если пользователь смотрит канал или это свой пост** — `actionsToMarkChannelAsRead()` (`channels.ts:1238`):
- `DECREMENT_UNREAD_MSG_COUNT` — синхронизирует `msg_count` с `total_msg_count`
- `DECREMENT_UNREAD_MENTION_COUNT` — обнуляет mentions
- `RECEIVED_LAST_VIEWED_AT` — обновляет `last_viewed_at`

## 4. Пометка канала как прочитанного (View Channel)

### API

```
POST /api/v4/channels/members/{user_id}/view
Body: {"channel_id": "...", "prev_channel_id": "..."}
```

### Серверная цепочка

1. `viewChannel` API handler (`channel.go:1749`)
2. `App.ViewChannel()` (`channel.go:3154`) -> `MarkChannelsAsViewed()`
3. `MarkChannelsAsViewed()` (`channel.go:3058`):
   - Фильтрует каналы, у которых реально есть непрочитанные
   - Вызывает `Store.Channel().UpdateLastViewedAt(channelIDs, userID)`
   - Отправляет WS-событие `multiple_channels_viewed`
4. `UpdateLastViewedAt()` SQL (`channel_store.go:2621`):

```sql
UPDATE ChannelMembers cm SET
    MentionCount = 0,
    MentionCountRoot = 0,
    UrgentMentionCount = 0,
    MsgCount = GREATEST(cm.MsgCount, c.TotalMsgCount),
    MsgCountRoot = GREATEST(cm.MsgCountRoot, c.TotalMsgCountRoot),
    LastViewedAt = GREATEST(cm.LastViewedAt, c.LastPostAt),
    LastUpdateAt = GREATEST(cm.LastViewedAt, c.LastPostAt),
    LastSeenAt = GREATEST(cm.LastSeenAt, c.LastPostAt)    -- кастомное поле MyGames
FROM Channels c
WHERE cm.UserId = ? AND c.Id = cm.ChannelId
```

`GREATEST` гарантирует, что значения никогда не уменьшаются (защита от race conditions при multi-device).

## 5. Пометка канала как непрочитанного с определённого поста

`UpdateLastViewedAtPost()` (`channel_store.go:2813`):

1. Вычисляет `unreadDate = post.CreateAt - 1`
2. `CountPostsAfter()` считает посты после этой даты (исключая системные join/leave)
3. Обновляет:

```sql
UPDATE ChannelMembers SET
    MentionCount = :mentions,
    MentionCountRoot = :mentionsroot,
    MsgCount = (SELECT TotalMsgCount FROM Channels WHERE ID = :channelid) - :unreadcount,
    MsgCountRoot = (SELECT TotalMsgCountRoot FROM Channels WHERE ID = :channelid) - :unreadcountroot,
    LastViewedAt = :lastviewedat
WHERE UserId = :userid AND ChannelId = :channelid
```

## 6. Настройка mark_unread

В `GetChannelUnread()` App-слоя (`channel.go:2247-2250`):

```go
if channelUnread.NotifyProps[model.MarkUnreadNotifyProp] == model.ChannelMarkUnreadMention {
    channelUnread.MsgCount = 0
    channelUnread.MsgCountRoot = 0
}
```

Для каналов с настройкой `mark_unread=mention` — `MsgCount` принудительно обнуляется, чтобы в sidebar показывались только @mentions.

## 7. Отображение на клиенте (sidebar)

### Redux-селекторы

- `makeGetChannelUnreadCount()` (`channels.ts:383`) — `{showUnread, messages, mentions, hasUrgent}` для конкретного канала
- `countCurrentChannelUnreadMessages()` (`channels.ts:370`) — непрочитанные в текущем канале
- `getUnreadStatus()` (`channels.ts:607`) — общий статус непрочитанных для title/favicon
- `getTeamsUnreadStatuses()` (`channels.ts:689`) — непрочитанные по командам

### Правило showUnread

```typescript
showUnread = mentions > 0 || (!isChannelMuted(member) && messages > 0)
```

Канал показывается непрочитанным, если:
- Есть упоминания, **ИЛИ**
- Канал не замьючен и есть непрочитанные сообщения

### Компоненты

- **`SidebarChannel`** (`sidebar/sidebar_channel/index.ts`) — контейнер, подключает `makeGetChannelUnreadCount()` к пропсам `unreadMentions` и `isUnread`
- **`SidebarChannelLink`** (`sidebar_channel_link.tsx`) — применяет CSS-класс `unread-title` при `isUnread=true`
- **`ChannelMentionBadge`** (`channel_mention_badge.tsx`) — числовой badge с количеством @mentions, с CSS-классом `urgent` для срочных

## 8. Итоговая схема потока данных

```
=== СЕРВЕР ===

Новый пост:
  Channels.TotalMsgCount++
  ChannelMembers.MentionCount++ (для упомянутых пользователей)
  -> Разница (TotalMsgCount - MsgCount) растёт = канал "непрочитан"

View Channel:
  ChannelMembers.MsgCount := Channels.TotalMsgCount
  ChannelMembers.MentionCount := 0
  -> Разница = 0 = канал "прочитан"

=== КЛИЕНТ (Redux) ===

WebSocket Event (posted)
    |
    v
setChannelReadAndViewed()
    |
    +-- Канал не просматривается:
    |     INCREMENT_TOTAL_MSG_COUNT    -> messageCounts[id].total++
    |     INCREMENT_UNREAD_MSG_COUNT   -> myMembers[id].msg_count++ (только mark_unread=mention)
    |     INCREMENT_UNREAD_MENTION_COUNT -> myMembers[id].mention_count++ (если @mention)
    |
    +-- Канал просматривается:
          DECREMENT_UNREAD_MSG_COUNT   -> myMembers[id].msg_count += разница
          DECREMENT_UNREAD_MENTION_COUNT -> myMembers[id].mention_count = 0
          RECEIVED_LAST_VIEWED_AT      -> myMembers[id].last_viewed_at = now
    |
    v
Селектор calculateUnreadCount()
  messages = messageCounts[id].total - myMembers[id].msg_count
  mentions = myMembers[id].mention_count
  showUnread = mentions > 0 || (!muted && messages > 0)
    |
    v
SidebarChannel -> SidebarChannelLink (unread-title) + ChannelMentionBadge
```

## Ключевые файлы

| Слой | Файл | Описание |
|------|------|----------|
| Model | `server/public/model/channel.go` | Структура Channel (TotalMsgCount) |
| Model | `server/public/model/channel_member.go` | ChannelMember, ChannelUnread |
| Store | `server/channels/store/sqlstore/channel_store.go` | GetChannelUnread, UpdateLastViewedAt, UpdateLastViewedAtPost, IncrementMentionCount, CountPostsAfter |
| Store | `server/channels/store/sqlstore/post_store.go` | savePosts (TotalMsgCount++) |
| Store | `server/channels/store/sqlstore/team_store.go` | GetChannelUnreadsForTeam/AllTeams |
| App | `server/channels/app/channel.go` | ViewChannel, MarkChannelsAsViewed, GetChannelUnread |
| API | `server/channels/api4/channel.go` | viewChannel, getChannelUnread endpoints |
| Types | `webapp/platform/types/src/channels.ts` | ChannelMembership, ChannelMessageCount |
| Utils | `webapp/.../mattermost-redux/src/utils/channel_utils.ts` | calculateUnreadCount() |
| Selectors | `webapp/.../mattermost-redux/src/selectors/entities/channels.ts` | makeGetChannelUnreadCount, getUnreadStatus |
| Actions | `webapp/.../mattermost-redux/src/actions/channels.ts` | actionsToMarkChannelAsRead/Unread |
| Actions | `webapp/channels/src/actions/new_post.ts` | completePostReceive, setChannelReadAndViewed |
| Actions | `webapp/channels/src/actions/websocket_actions.jsx` | handleNewPostEvent |
| Reducers | `webapp/.../mattermost-redux/src/reducers/entities/channels.ts` | myMembers reducer (INCREMENT/DECREMENT actions) |
| Reducers | `webapp/.../reducers/entities/channels/message_counts.ts` | messageCounts reducer |
| UI | `webapp/channels/src/components/sidebar/sidebar_channel/` | SidebarChannel, SidebarChannelLink, ChannelMentionBadge |
