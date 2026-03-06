# План исправления: ложные непрочитанные каналы и неправильная позиция отбивки даты

## Баг 1: Каналы показываются непрочитанными, хотя в оригинальном приложении они прочитаны

### Диагноз

Текущая логика определения непрочитанности (`lib/domain/entities/channel.dart:54-56`):

```dart
int get unreadCount => isMuted ? 0 : totalMsgCount - msgCount;
bool get hasUnread => !isMuted && (totalMsgCount - msgCount) > 0;
```

Используется разница `totalMsgCount - msgCount`. Проблема в том, что при включённом на сервере **CRT (Collapsed Reply Threads)**:

- `total_msg_count` на канале считает **ВСЕ** сообщения: корневые + ответы в тредах
- `msg_count` в ChannelMember обновляется при просмотре канала, но отражает только **корневые** посты, которые пользователь видел

Результат: `totalMsgCount - msgCount > 0` даже когда все корневые посты прочитаны, потому что `totalMsgCount` раздут ответами в тредах. Это и вызывает ложные непрочитанные.

### Дополнительная проблема: неполное обогащение данных

В `lib/data/repositories/channel_repository_impl.dart:72-77` при enrichment каналов данными membership НЕ заполняются CRT-счётчики:

```dart
return channel.copyWith(
  msgCount: (member['msg_count'] as num?)?.toInt() ?? 0,
  mentionCount: (member['mention_count'] as num?)?.toInt() ?? 0,
  lastViewedAt: (member['last_viewed_at'] as num?)?.toInt() ?? 0,
  isMuted: isMuted,
  // ОТСУТСТВУЮТ: msgCountRoot, mentionCountRoot, urgentMentionCount
);
```

При этом `totalMsgCountRoot` заполняется в `ChannelModel.fromJson` (строка 41), а `msgCountRoot` остаётся 0.

### План исправления

#### Шаг 1: Добавить CRT-счётчики в enrichment репозитория

**Файл:** `lib/data/repositories/channel_repository_impl.dart` (строки 72-77)

```dart
return channel.copyWith(
  msgCount: (member['msg_count'] as num?)?.toInt() ?? 0,
  msgCountRoot: (member['msg_count_root'] as num?)?.toInt() ?? 0,
  mentionCount: (member['mention_count'] as num?)?.toInt() ?? 0,
  mentionCountRoot: (member['mention_count_root'] as num?)?.toInt() ?? 0,
  urgentMentionCount: (member['urgent_mention_count'] as num?)?.toInt() ?? 0,
  lastViewedAt: (member['last_viewed_at'] as num?)?.toInt() ?? 0,
  isMuted: isMuted,
);
```

#### Шаг 2: Переключить hasUnread и unreadCount на root-счётчики

**Файл:** `lib/domain/entities/channel.dart` (строки 54-56)

```dart
int get unreadCount => isMuted ? 0 : totalMsgCountRoot - msgCountRoot;
bool get hasUnread => !isMuted && (totalMsgCountRoot - msgCountRoot) > 0;
```

#### Шаг 3: Обновить WS-обработчик `_handleNewPost` в ChannelsBloc

**Файл:** `lib/presentation/screens/channels/channels_bloc.dart`

При получении WS-события `posted` для НЕ-тредового сообщения (rootId пустой) нужно инкрементировать и root-счётчики. Для ответов в тредах (rootId не пустой) НЕ инкрементировать root-счётчики. Текущая логика уже различает треды, но инкрементирует `totalMsgCountRoot` для всех постов — нужно исправить, чтобы root-счётчики росли только для корневых постов.

#### Шаг 4: Обновить WS-обработчики `_handleChannelViewed` и `_handleMultipleChannelsViewed`

Убедиться, что при пометке канала прочитанным синхронизируются и root-счётчики:

```dart
return c.copyWith(
  msgCount: c.totalMsgCount,
  msgCountRoot: c.totalMsgCountRoot,
  mentionCount: 0,
  mentionCountRoot: 0,
  urgentMentionCount: 0,
);
```

(Уже реализовано — проверить что `msgCountRoot` и `mentionCountRoot` обнуляются.)

#### Шаг 5: Обновить `_onMarkChannelAsRead`

Аналогично шагу 4 — убедиться в синхронизации root-счётчиков при оптимистичном обновлении.

#### Шаг 6: Обновить тесты

- Unit-тесты Channel entity: проверить `hasUnread`/`unreadCount` с CRT-счётчиками
- Unit-тесты ChannelsBloc: проверить, что тредовые посты не создают unread
- Unit-тесты channel_repository: проверить enrichment с root-полями

---

## Баг 2: Отбивка "Today" отображается ПОД сообщением, а не НАД

### Диагноз

В `lib/presentation/screens/chat/chat_screen.dart:372-415` разделитель даты размещён **ПОСЛЕ** `MessageBubble` в `Column`:

```dart
return Column(
  children: [
    MessageBubble(...),                              // строка 374
    if (showUnreadSeparator) _buildUnreadSeparator(), // строка 411
    if (showDateSeparator) _buildDateSeparator(...),  // строка 412
  ],
);
```

ListView использует `reverse: true` (строка 352), что означает:
- index 0 (новейший пост) рендерится **внизу** экрана
- Более высокие индексы — **выше** на экране
- Внутри каждого Column порядок стандартный: первый элемент сверху, последний снизу

Результат: разделитель даты рендерится **ниже** сообщения, а должен быть **выше** (как заголовок группы дня).

### Визуально (текущее поведение — неправильно)

```
[Сообщение 5 марта]          <- index+1
[Сообщение 6 марта]          <- index (новая дата)
━━━━━━━ Today ━━━━━━━        <- разделитель НИЖЕ сообщения (НЕПРАВИЛЬНО)
[Сообщение 6 марта]          <- index-1
```

### Визуально (правильное поведение)

```
[Сообщение 5 марта]          <- index+1
━━━━━━━ Today ━━━━━━━        <- разделитель ВЫШЕ группы (ПРАВИЛЬНО)
[Сообщение 6 марта]          <- index
[Сообщение 6 марта]          <- index-1
```

### План исправления

#### Шаг 1: Переместить разделители в начало Column

**Файл:** `lib/presentation/screens/chat/chat_screen.dart` (строки 372-415)

```dart
return Column(
  children: [
    if (showDateSeparator)
      _buildDateSeparator(post.createAt),
    if (showUnreadSeparator)
      _buildUnreadSeparator(),
    MessageBubble(...),
  ],
);
```

Порядок: дата-разделитель -> разделитель непрочитанных -> сообщение. Это гарантирует:
- Дата отображается как заголовок группы дня (выше всех сообщений этого дня)
- "New messages" отображается над первым непрочитанным сообщением

#### Шаг 2: Проверить корректность timestamp

Убедиться, что `_buildDateSeparator(post.createAt)` использует timestamp текущего поста (новой даты), а не предыдущего. Текущий код уже использует `post.createAt` — это правильно, так как разделитель маркирует группу ниже себя.

#### Шаг 3: Проверить edge case для самого старого поста

`_needsDateSeparator` возвращает `true` для `index == posts.length - 1` (самый старый пост). После исправления разделитель будет отображаться ВЫШЕ этого поста — это корректное поведение (заголовок первой группы дат).

#### Шаг 4: Обновить интеграционные тесты

Если есть тесты на порядок виджетов в списке сообщений — обновить ожидаемый порядок (separator перед MessageBubble).

---

## Порядок выполнения

1. **Баг 2 (дата-разделитель)** — быстрое исправление, одна строка перестановки в Column
2. **Баг 1 (непрочитанные)** — требует изменений в 3-4 файлах:
   - `channel.dart` (entity)
   - `channel_repository_impl.dart` (enrichment)
   - `channels_bloc.dart` (WS-обработчики)
   - Тесты
3. Запустить `flutter test` для проверки
4. Проверить на симуляторе оба исправления

## Затронутые файлы

| Файл | Изменение |
|------|-----------|
| `lib/domain/entities/channel.dart` | `hasUnread`/`unreadCount` -> root-счётчики |
| `lib/data/repositories/channel_repository_impl.dart` | Добавить CRT-поля в enrichment |
| `lib/presentation/screens/channels/channels_bloc.dart` | Проверить WS-обработчики root-счётчиков |
| `lib/presentation/screens/chat/chat_screen.dart` | Переместить separator перед MessageBubble |
| `test/blocs/channels_bloc_test.dart` | Обновить тесты unread |
| `test/models/channel_model_test.dart` | Добавить тесты CRT-полей |
