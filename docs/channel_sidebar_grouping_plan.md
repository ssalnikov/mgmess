# План: Группировка каналов в боковой панели (как в Mattermost Web)

> **Статус:** Полностью реализовано (все 12 фаз).

## Цель

Реализовать в MGMess группировку каналов по аналогии с Mattermost Web при настройках:
- **Group unread channels separately** = ON
- **Show muted channels in recents section** = OFF
- **Number of direct messages to show** = 40
- **Number of recent channels to show** = 60

## Анализ Mattermost Web

### Как это работает в Web-приложении

#### Структура списка каналов

При включённой группировке непрочитанных каналов веб-клиент показывает:

```
┌──────────────────────────────────┐
│ НЕПРОЧИТАННЫЕ И НЕДАВНИЕ         │
│   ● Канал с mentions (бэйдж)    │
│   ● Непрочитанный канал          │
│   ● Непрочитанный DM             │
│   ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
│     Недавний канал 1             │
│     Недавний канал 2             │
│     ...                          │
│     (до 60 шт, без дублей)       │
├──────────────────────────────────┤
│ ИЗБРАННЫЕ                        │
│     Избранный канал              │
├──────────────────────────────────┤
│ КАНАЛЫ                           │
│     Публичный канал              │
│     Приватный канал              │
├──────────────────────────────────┤
│ ЛИЧНЫЕ СООБЩЕНИЯ                 │
│     DM-канал                     │
│     (до 40 шт)                   │
└──────────────────────────────────┘
```

#### Поток данных (из исходников Web)

1. **Категории с сервера**: `GET /api/v4/users/{user_id}/teams/{team_id}/channels/categories`
   - Возвращает `{ categories: ChannelCategory[], order: string[] }`
   - Стандартные типы: `FAVORITES`, `CHANNELS`, `DIRECT_MESSAGES`, `CUSTOM`

2. **Формирование UNREADS псевдо-категории** (`channel_sidebar.ts:143-197`):
   - Собрать все каналы из `unreadChannelIds`
   - Отфильтровать удалённые (`delete_at > 0`, кроме текущего)
   - Сортировка `sortUnreadChannels()`:
     - Muted → в конец
     - С mentions → первые
     - По `last_post_at` (или `last_root_post_at` при CRT) → по убыванию

3. **Формирование секции Recent** (`unread_channels.tsx:37-40`):
   - Берутся ВСЕ каналы из обычных категорий (кроме тех, что уже в UNREADS)
   - Фильтруются muted (если "Show muted in recents" = OFF)
   - Сортируются по `last_post_at` в убывающем порядке
   - Берутся первые N (`recentCountSetting`, в нашем случае 60)
   - Исключаются каналы, уже присутствующие в списке UNREADS
   - Заголовок секции: `"UNREADS & RECENTS"` (если recentCount > 0), иначе `"UNREADS"`

4. **Фильтрация DM** (`channel_categories.ts:95-195`):
   - Непрочитанные DM видны всегда
   - Текущий открытый DM виден всегда
   - DM с деактивированными пользователями скрываются (если последний просмотр до деактивации)
   - Остальные DM сортируются: текущий → непрочитанные → по `last_viewed_at`
   - Берутся первые `Math.max(limitPref, unreadCount)` (т.е. если непрочитанных > лимита, все видны)

5. **Исключение из обычных категорий** (`channel_sidebar.ts:71-105`):
   - Если `showUnreadsCategory = true`, каналы с `unread` убираются из своих обычных категорий (Favorites, Channels, DMs)
   - Если категория свёрнута (`collapsed`), прочитанные каналы скрываются

6. **Фильтрация muted** (`channel_sidebar.ts:107-139`):
   - Если "Show muted in recents" = OFF, muted каналы убираются из **всех** категорий (включая Recent)

#### Сортировка внутри категорий

| Категория | Сортировка по умолчанию |
|-----------|------------------------|
| UNREADS | Muted → в конец, затем mentions первые, затем по recency |
| RECENTS | По `last_post_at` ↓ |
| FAVORITES | Alphabetical (DM по displayName) |
| CHANNELS | Alphabetical |
| DIRECT_MESSAGES | По recency или alphabetical (настраивается) |

---

## Текущая реализация в MGMess

### Что есть сейчас
- **Плоский список** каналов, отсортированный по `lastPostAt` ↓ (новые вверху)
- Фиксированные элементы вверху: Threads, Drafts
- Индикаторы: unread точка, mentions бэйдж, mute иконка
- Поиск: локальный + серверный автокомплит
- WebSocket обновления: `posted`, `channelViewed`, `channelMemberUpdated`
- CRT счётчики: `totalMsgCountRoot`, `msgCountRoot`, `mentionCountRoot`
- `isMuted` на сущности Channel

### Что нужно добавить
- Группировка по секциям (UNREADS & RECENTS, FAVORITES, CHANNELS, DMs)
- Фильтрация по настройкам (muted, DM limit, recent limit)
- Серверные категории каналов (API `/channels/categories`)

---

## План реализации

### Фаза 1: Модели и данные

#### 1.1 Сущность ChannelCategory (Domain)

**Файл:** `lib/domain/entities/channel_category.dart`

```dart
enum ChannelCategoryType { favorites, channels, directMessages, custom }
enum ChannelCategorySorting { alphabetical, recency, manual, default_ }

class ChannelCategory extends Equatable {
  final String id;
  final String teamId;
  final String userId;
  final ChannelCategoryType type;
  final String displayName;
  final bool collapsed;
  final List<String> channelIds;
  final ChannelCategorySorting sorting;
  final bool muted;
}
```

#### 1.2 Модель ChannelCategoryModel (Data)

**Файл:** `lib/data/models/channel_category_model.dart`

```dart
class ChannelCategoryModel {
  // fromJson/toJson для API ответа
  // Преобразование строковых типов в enum
  // toEntity() → ChannelCategory
}
```

#### 1.3 Remote DataSource метод

**Файл:** `lib/data/datasources/remote/channel_remote_data_source.dart`

Добавить метод:
```dart
Future<List<ChannelCategoryModel>> getChannelCategories(String userId, String teamId);
// GET /api/v4/users/{userId}/teams/{teamId}/channels/categories
// Response: { categories: [...], order: [...] }
```

#### 1.4 Repository метод

**Файл:** `lib/domain/repositories/channel_repository.dart`

```dart
Future<Either<Failure, List<ChannelCategory>>> getChannelCategories(String userId, String teamId);
```

---

### Фаза 2: Настройки sidebar

#### 2.1 Модель настроек

**Файл:** `lib/domain/entities/sidebar_settings.dart`

```dart
class SidebarSettings {
  final bool groupUnreadsSeparately;  // default: true
  final bool showMutedInRecents;       // default: false
  final int dmLimit;                   // default: 40
  final int recentChannelsLimit;       // default: 60
}
```

Настройки хранятся на сервере в user preferences (`sidebar_settings--*`). Для первой итерации можно захардкодить значения (как указано в задании), добавив экран настроек позднее.

---

### Фаза 3: Логика группировки в ChannelsBloc

#### 3.1 Новые состояния

**Файл:** `lib/presentation/screens/channels/channels_bloc.dart`

Добавить в `ChannelsState`:
```dart
class ChannelsState {
  // Существующие поля...
  final List<Channel> channels;

  // Новые поля:
  final List<Channel> unreadChannels;     // Непрочитанные (сортированные)
  final List<Channel> recentChannels;     // Недавние (top-N, без дублей с unreads)
  final List<ChannelCategory> categories; // Категории с сервера
  final Map<String, List<Channel>> channelsByCategory; // Каналы по категориям (без unreads)
}
```

#### 3.2 Алгоритм группировки (ключевая логика)

Метод `_groupChannels()` в ChannelsBloc:

```
Вход: List<Channel> allChannels, List<ChannelCategory> categories, SidebarSettings settings

Шаг 1: ФИЛЬТРАЦИЯ DM
  - Из категории DIRECT_MESSAGES:
    - Всегда показывать непрочитанные DM
    - Всегда показывать текущий открытый DM
    - Скрыть DM с деактивированными пользователями
    - Остальные: сортировать по last_viewed_at, взять первые max(dmLimit, unreadCount)

Шаг 2: ВЫДЕЛЕНИЕ НЕПРОЧИТАННЫХ
  - Если groupUnreadsSeparately:
    - Собрать все каналы с hasUnread || hasMention из всех категорий
    - Сортировка: muted → в конец, mentions → первые, потом по lastPostAt ↓
    - Убрать эти каналы из их обычных категорий

Шаг 3: ФОРМИРОВАНИЕ RECENT
  - Если recentChannelsLimit > 0:
    - Взять ВСЕ каналы из обычных категорий (после удаления unread)
    - Если !showMutedInRecents: убрать muted
    - Сортировать по lastPostAt ↓
    - Взять первые recentChannelsLimit
    - Убрать каналы, уже присутствующие в unreadChannels

Шаг 4: ФИЛЬТРАЦИЯ MUTED
  - Если !showMutedInRecents:
    - Убрать muted каналы из всех обычных категорий

Шаг 5: ФОРМИРОВАНИЕ channelsByCategory
  - Для каждой категории: каналы, оставшиеся после шагов 2+4
  - Сортировка внутри категории по sorting (alphabetical/recency/manual)

Выход: unreadChannels, recentChannels, channelsByCategory
```

#### 3.3 Обработка WebSocket событий

Существующие обработчики `posted`, `channelViewed`, `channelMemberUpdated` уже обновляют счётчики. После обновления нужно вызывать `_groupChannels()` для пересчёта группировки.

Добавить обработку WS событий:
- `sidebar_category_created` — новая пользовательская категория
- `sidebar_category_updated` — изменение категории (перемещение каналов)
- `sidebar_category_deleted` — удаление категории

---

### Фаза 4: UI — Сгруппированный список

#### 4.1 Структура экрана каналов

**Файл:** `lib/presentation/screens/channels/channels_screen.dart`

```
CustomScrollView
├── SliverToBoxAdapter: Threads link
├── SliverToBoxAdapter: Drafts link
│
├── // --- UNREADS & RECENTS секция ---
├── SliverToBoxAdapter: Заголовок "НЕПРОЧИТАННЫЕ И НЕДАВНИЕ"
├── SliverList: unreadChannels (с индикаторами mentions/unread)
├── SliverList: recentChannels (без индикатора unread)
│
├── // --- FAVORITES секция (если есть) ---
├── SliverToBoxAdapter: Заголовок "ИЗБРАННЫЕ" (сворачиваемый)
├── SliverList: favoriteChannels
│
├── // --- CHANNELS секция ---
├── SliverToBoxAdapter: Заголовок "КАНАЛЫ" (сворачиваемый)
├── SliverList: regularChannels
│
├── // --- DIRECT MESSAGES секция ---
├── SliverToBoxAdapter: Заголовок "ЛИЧНЫЕ СООБЩЕНИЯ" (сворачиваемый)
├── SliverList: dmChannels (до 40 шт)
│
├── // --- CUSTOM категории ---
├── SliverToBoxAdapter: Заголовок категории
├── SliverList: каналы категории
```

#### 4.2 Виджет заголовка секции

**Файл:** `lib/presentation/screens/channels/widgets/category_header.dart`

```dart
class CategoryHeader extends StatelessWidget {
  final String title;
  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback? onMarkAllRead;  // Только для UNREADS
  final int? unreadCount;             // Бэйдж на заголовке
}
```

#### 4.3 Визуальное разделение Unreads и Recents

Внутри секции "НЕПРОЧИТАННЫЕ И НЕДАВНИЕ":
- Непрочитанные каналы отображаются с жирным названием и индикаторами (как сейчас)
- Недавние каналы отображаются обычным шрифтом, без индикатора unread
- Между ними можно добавить тонкий разделитель (Divider)

---

### Фаза 5: Сворачивание категорий

#### 5.1 Хранение состояния свёрнутости

Состояние `collapsed` приходит с сервера в `ChannelCategory.collapsed`. При сворачивании/разворачивании:
- Оптимистично обновить UI
- Отправить `PUT /api/v4/users/{userId}/teams/{teamId}/channels/categories/{categoryId}` с обновлённым `collapsed`

#### 5.2 Логика при свёрнутой категории

- Прочитанные каналы скрываются
- Непрочитанные каналы остаются видны (показываются в UNREADS секции)
- Текущий открытый канал остаётся видим в своей категории

---

### Фаза 6: Взаимодействие с сервером

#### 6.1 API endpoints

| Метод | Endpoint | Назначение |
|-------|----------|------------|
| GET | `/users/{id}/teams/{id}/channels/categories` | Загрузить все категории |
| PUT | `/users/{id}/teams/{id}/channels/categories/{id}` | Обновить категорию (collapsed, sorting) |
| POST | `/users/{id}/teams/{id}/channels/categories` | Создать пользовательскую категорию |
| DELETE | `/users/{id}/teams/{id}/channels/categories/{id}` | Удалить пользовательскую категорию |

#### 6.2 Загрузка категорий

При загрузке каналов (`LoadChannels` event) параллельно загружать категории:
```dart
final results = await Future.wait([
  _channelRepository.getChannelsForUser(userId, teamId),
  _channelRepository.getChannelCategories(userId, teamId),
]);
```

---

### Фаза 7: Кеширование (Drift/SQLite)

#### 7.1 Таблица ChannelCategories

**Файл:** `lib/data/datasources/local/app_database.dart`

```dart
class ChannelCategories extends Table {
  TextColumn get id => text()();
  TextColumn get teamId => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()(); // favorites, channels, direct_messages, custom
  TextColumn get displayName => text()();
  BoolColumn get collapsed => boolean().withDefault(const Constant(false))();
  TextColumn get channelIds => text()(); // JSON-encoded List<String>
  TextColumn get sorting => text().withDefault(const Constant('default'))();
  BoolColumn get muted => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### 7.2 DAO и LocalDataSource

Аналогично существующим DAO — CRUD операции + маппер в entity.

---

## Порядок реализации

| # | Задача | Зависимости | Оценка сложности |
|---|--------|-------------|-----------------|
| 1 | Entity `ChannelCategory` + Model + fromJson | — | Низкая |
| 2 | Remote DataSource: `getChannelCategories()` | #1 | Низкая |
| 3 | Repository метод + impl | #2 | Низкая |
| 4 | Drift таблица + DAO + LocalDataSource + миграция | #1 | Средняя |
| 5 | `SidebarSettings` (захардкоженные значения) | — | Низкая |
| 6 | Алгоритм группировки в ChannelsBloc | #3, #5 | Высокая |
| 7 | UI: `CategoryHeader` виджет | — | Низкая |
| 8 | UI: Сгруппированный список (CustomScrollView + Slivers) | #6, #7 | Высокая |
| 9 | Сворачивание категорий (UI + API) | #8 | Средняя |
| 10 | WS обработка `sidebar_category_*` событий | #6 | Средняя |
| 11 | Unit-тесты на алгоритм группировки | #6 | Средняя |
| 12 | Integration-тесты сгруппированного списка | #8 | Средняя |

## Риски и решения

| Риск | Решение |
|------|---------|
| Сервер может не поддерживать `/channels/categories` API | Проверить API, при ошибке — fallback на плоский список с локальной группировкой по `channel.type` |
| Производительность при 100+ каналах | Использовать `CustomScrollView` + `SliverList` (ленивый рендеринг), мемоизировать группировку |
| Частый пересчёт группировки при WS-событиях | Пересчитывать только изменённую секцию; debounce при серии быстрых событий |
| Несинхронность категорий между устройствами | WS-события `sidebar_category_*` для real-time синхронизации |

## Заметки

- В первой итерации настройки захардкожены. Экран настроек sidebar можно добавить позднее.
- Категория UNREADS — это **псевдо-категория**, которая не существует на сервере. Она формируется клиентом на основе unread-статуса каналов.
- "Mark all as read" для секции UNREADS — batch API: `POST /channels/members/{userId}/mark_read` (или по одному через `channelViewed`).
- При `recentChannelsLimit = 60` заголовок секции: "НЕПРОЧИТАННЫЕ И НЕДАВНИЕ", при `0`: "НЕПРОЧИТАННЫЕ".
