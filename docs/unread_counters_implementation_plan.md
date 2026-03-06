# Счётчики непрочитанных: сравнение с веб-клиентом и план реализации

## Сравнительный анализ

### Что уже реализовано в MGMess (совпадает с веб-клиентом)

| Функциональность | Веб-клиент | MGMess | Статус |
|---|---|---|---|
| Формула `totalMsgCount - msgCount` | `calculateUnreadCount()` | `Channel.unreadCount` getter | Реализовано |
| Инкремент `totalMsgCount` при WS `posted` | `INCREMENT_TOTAL_MSG_COUNT` | `_handleNewPost`: `totalMsgCount + 1` | Реализовано |
| Свой пост — unread не растёт | `DECREMENT_UNREAD_MSG_COUNT` | `msgCount + 1` вместе с `totalMsgCount + 1` | Реализовано |
| Инкремент `mentionCount` при @mention | `INCREMENT_UNREAD_MENTION_COUNT` | Проверка `mentions.contains(_userId)` | Реализовано |
| Thread reply не влияет на канал | Проверка `isCRTReply` | Проверка `rootId.isNotEmpty` → early return | Реализовано |
| `MarkChannelAsRead` при входе в чат | `actionsToMarkChannelAsRead` | `MarkChannelAsRead` + `viewChannel` API | Реализовано |
| Мьюченные каналы не показываются непрочитанными | `!isChannelMuted(member) && messages > 0` | `hasUnread && !isMuted` в UI | Реализовано |
| Обработка WS `channel_viewed` | `markMultipleChannelsAsRead` | `_handleChannelViewed` | Реализовано |
| Badge на иконке приложения | Desktop API | `AppBadgePlus.updateBadge()` | Реализовано |
| Отображение badge с mention count | `ChannelMentionBadge` | Красный badge в `_buildTrailing()` | Реализовано |
| Жирный текст для непрочитанных | CSS `unread-title` | `fontWeight: FontWeight.bold` | Реализовано |
| `viewChannel` API при выходе из чата | `markChannelAsViewedOnServer` | `dispose()` → `viewChannel()` | Реализовано |

### Что отсутствует в MGMess

#### 1. Нет поддержки CRT (Collapsed Reply Threads) счётчиков

**Веб-клиент:** поддерживает два режима подсчёта:
- CRT выключен: `messageCount.total - member.msg_count`, `member.mention_count`
- CRT включен: `messageCount.root - member.msg_count_root`, `member.mention_count_root`

**MGMess:** использует только `totalMsgCount`/`msgCount`/`mentionCount`. Поля `*Root` и `urgentMentionCount` отсутствуют.

**Влияние:** При включённом CRT на сервере счётчики могут расходиться — thread replies будут считаться на клиенте иначе, чем на сервере. Сейчас обходится тем, что MGMess всегда игнорирует replies (`rootId.isNotEmpty` → skip), что по сути эмулирует CRT-подобное поведение, но `msg_count_root` и `total_msg_count_root` с сервера не используются.

#### 2. Нет обработки WS `multiple_channels_viewed`

**Веб-клиент:** обрабатывает `multiple_channels_viewed` — помечает несколько каналов прочитанными одним событием (приходит при ViewChannel с multi-device).

**MGMess:** тип события объявлен в `WsEventType`, но нигде не обрабатывается. Из-за этого при чтении канала на другом устройстве badge в MGMess не сбрасывается до следующего RefreshChannels.

#### 3. Нет обработки `channel_member_updated`

**Веб-клиент:** обновляет membership при `channel_member_updated` (например, при mute/unmute с другого устройства).

**MGMess:** не обрабатывает — mute-статус обновляется только локально.

#### 4. `lastViewedAt` при входе в чат берётся неправильно

**Веб-клиент:** `lastViewedAt` для отрисовки разделителя "New messages" берётся из `ChannelMembership.last_viewed_at` (серверное значение).

**MGMess:** передаёт `DateTime.now().millisecondsSinceEpoch` при открытии канала (`channels_screen.dart:287`). Это означает, что разделитель "New messages" никогда не отображается корректно — он всегда будет "сейчас", а не с момента реального последнего просмотра.

#### 5. Нет оптимистичного обновления при Mark as Read

**Веб-клиент:** при нажатии на канал сначала обновляет Redux-стор локально (`actionsToMarkChannelAsRead`), потом вызывает API.

**MGMess:** делает то же самое (`MarkChannelAsRead` обновляет state, затем вызывает `viewChannel`), но при ошибке API не откатывает state обратно.

#### 6. Нет учёта `mark_unread=mention` при подсчёте сообщений

**Веб-клиент:** если у канала `mark_unread=mention`, `MsgCount` обнуляется на сервере (`GetChannelUnread`, `channel.go:2247`) и на клиенте (`onlyMentions` в reducer).

**MGMess:** при `isMuted=true` UI скрывает badge непрочитанных (показывает только иконку mute), но в формуле `unreadCount` всё равно считает messages. Это не баг в UI (muted скрывает), но `unreadCount` getter логически некорректен для muted каналов.

#### 7. Нет отдельного `viewChannel` при входе в чат (только при выходе)

**Веб-клиент:** вызывает `viewChannel` и при входе (чтобы сервер сразу обновил `ChannelMembers`), и при потере фокуса.

**MGMess:** вызывает `viewChannel` API только при `dispose()` ChatScreen. При входе — только локальный `MarkChannelAsRead`. Это означает, что сервер не знает о прочтении до момента выхода из чата, и push-уведомления продолжают приходить.

#### 8. Нет fallback на `getChannelUnread` API

**Веб-клиент:** при рассинхронизации может запросить `GET /channels/{id}/unread` для получения точных серверных данных.

**MGMess:** полагается только на начальную загрузку (batch `getChannelMembersForUser`) и WS-события. Если WS-событие потеряно (разрыв соединения), счётчики уезжают до следующего pull-to-refresh.

#### 9. Нет синхронизации при reconnect WebSocket

**Веб-клиент:** при reconnect получает `hello` и перезагружает все данные, включая unreads.

**MGMess:** не описана логика перезагрузки unreads после WS reconnect (нужно проверить WebSocketBloc).

---

## План реализации

### Этап 1: Критические исправления (влияют на UX прямо сейчас)

#### 1.1. viewChannel при входе в чат
**Проблема:** push-уведомления продолжают приходить, пока пользователь читает канал.
**Решение:** вызывать `viewChannel` API при `initState` ChatScreen (не только при `dispose`).

Файлы:
- `lib/presentation/screens/chat/chat_screen.dart` — добавить вызов `viewChannel` в `initState`

#### 1.2. Передавать серверный `lastViewedAt` при навигации
**Проблема:** разделитель "New messages" всегда показывает текущее время.
**Решение:** передавать `channel.lastViewedAt` из Channel entity вместо `DateTime.now()`.

Файлы:
- `lib/presentation/screens/channels/channels_screen.dart:287` — заменить `DateTime.now()` на `channel.lastViewedAt`

#### 1.3. Обработка WS `multiple_channels_viewed`
**Проблема:** каналы не помечаются прочитанными при чтении с другого устройства.
**Решение:** добавить обработчик в `ChannelsBloc._onWsEvent`.

Файлы:
- `lib/presentation/screens/channels/channels_bloc.dart` — добавить case для `multipleChannelsViewed`, парсить `channel_times` и обновлять `msgCount/mentionCount`

### Этап 2: Надёжность (устранение рассинхронизации)

#### 2.1. Перезагрузка unreads после WS reconnect
**Проблема:** потерянные WS-события при разрыве не компенсируются.
**Решение:** при WS `hello` событии (reconnect) вызывать `RefreshChannels`.

Файлы:
- `lib/presentation/screens/channels/channels_bloc.dart` — добавить обработку `WsEventType.hello` → `RefreshChannels`

#### 2.2. Rollback при ошибке viewChannel
**Проблема:** если API viewChannel вернул ошибку, локальный state уже показывает "прочитано".
**Решение:** при ошибке `viewChannel` в `_onMarkChannelAsRead` — откатить `msgCount/mentionCount` обратно.

Файлы:
- `lib/presentation/screens/channels/channels_bloc.dart` — сохранить old values, восстановить при ошибке

### Этап 3: Полнота данных (CRT и root-счётчики)

#### 3.1. Добавить CRT-поля в Channel entity и модель
**Проблема:** нет `totalMsgCountRoot`, `msgCountRoot`, `mentionCountRoot`, `urgentMentionCount`.
**Решение:** добавить поля, парсить из JSON, хранить в локальной БД.

Файлы:
- `lib/domain/entities/channel.dart` — добавить поля
- `lib/data/models/channel_model.dart` — парсить `total_msg_count_root`, `msg_count_root`, `mention_count_root`, `urgent_mention_count`
- `lib/data/datasources/local/app_database.dart` — добавить колонки в Channels table, bump schemaVersion
- `lib/data/datasources/local/mappers/channel_mapper.dart` — маппинг новых полей
- `lib/data/datasources/local/daos/channel_dao.dart` — обновить queries

#### 3.2. Учитывать CRT в формуле unreadCount
**Решение:** если CRT включён, использовать `totalMsgCountRoot - msgCountRoot` вместо `totalMsgCount - msgCount`.

Файлы:
- `lib/domain/entities/channel.dart` — модифицировать getter `unreadCount` (или добавить метод с параметром `crtEnabled`)
- `lib/presentation/screens/channels/channels_bloc.dart` — использовать CRT-aware формулу

#### 3.3. Обновить WS-обработчик для CRT-полей
**Решение:** при `posted` инкрементировать root-счётчики если `rootId.isEmpty`.

Файлы:
- `lib/presentation/screens/channels/channels_bloc.dart` — `_handleNewPost`

### Этап 4: Улучшения UX

#### 4.1. Обработка `channel_member_updated` WS-события
**Решение:** обновлять `isMuted` и notify_props при получении WS-события.

Файлы:
- `lib/presentation/screens/channels/channels_bloc.dart` — добавить обработчик

#### 4.2. Показывать `urgentMentionCount` с визуальным отличием
**Решение:** добавить красный badge с восклицательным знаком для urgent mentions.

Файлы:
- `lib/presentation/screens/channels/channels_screen.dart` — модифицировать `_buildTrailing()`

#### 4.3. Корректный `unreadCount` для muted каналов
**Решение:** для каналов с `mark_unread=mention` unreadCount = 0, показывать только mentions.

Файлы:
- `lib/domain/entities/channel.dart` — обновить getter `hasUnread` с учётом `isMuted`

---

## Приоритет и оценка

| Этап | Задача | Приоритет | Сложность |
|------|--------|-----------|-----------|
| 1.1 | viewChannel при входе | Критический | Низкая |
| 1.2 | Серверный lastViewedAt | Критический | Низкая |
| 1.3 | multiple_channels_viewed | Критический | Низкая |
| 2.1 | Reload при WS reconnect | Высокий | Низкая |
| 2.2 | Rollback при ошибке API | Средний | Низкая |
| 3.1 | CRT-поля в модели | Средний | Средняя |
| 3.2 | CRT-формула | Средний | Низкая |
| 3.3 | CRT в WS-обработчике | Средний | Низкая |
| 4.1 | channel_member_updated | Низкий | Низкая |
| 4.2 | Urgent mentions UI | Низкий | Низкая |
| 4.3 | Muted unreadCount | Низкий | Низкая |
