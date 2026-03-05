# План реализации: Шапка канала с количеством участников и экран управления каналом

## Обзор

В оригинальном мобильном приложении Mattermost при нажатии на шапку (AppBar) канала открывается экран **Channel Info** с полной информацией о канале и действиями управления. В шапке также отображается количество участников канала. В MGMess этот функционал отсутствует — AppBar содержит только название канала и кнопку закреплённых сообщений.

## Текущее состояние

### Что есть
- `ChatScreen` AppBar отображает название канала (для DM — аватар + имя)
- Кнопка pinned messages в AppBar
- `Channel` entity содержит `header`, `purpose`, `displayName`, но **не содержит `memberCount`**
- `ChannelRemoteDataSource` имеет метод `getChannelMembers()`, но он не используется в репозитории
- Мьютинг/размьютинг каналов реализован

### Чего нет
- Поле `memberCount` в `Channel` entity
- API вызов `/channels/{id}/stats` для получения статистики канала
- Экран Channel Info
- BLoC/Cubit для управления состоянием Channel Info
- Возможность покинуть канал, редактировать канал, управлять участниками

## Поведение оригинального приложения Mattermost

### Шапка канала (AppBar)
- Название канала + подзаголовок с количеством участников (например, "12 members")
- Для DM-каналов — аватар, имя, статус пользователя
- Вся шапка кликабельна — по тапу открывается Channel Info

### Экран Channel Info
При тапе на шапку открывается экран с секциями:

1. **Заголовок** — иконка канала, название, тип (public/private)
2. **Header** — текст заголовка канала (Markdown)
3. **Purpose** — описание/цель канала
4. **Быстрые действия** (горизонтальная панель иконок):
   - Mute/Unmute
   - Favorites (добавить в избранное)
   - Search in channel
5. **Участники** — количество участников, по тапу открывается список
6. **Pinned Messages** — переход к закреплённым сообщениям
7. **Notification Preferences** — настройки уведомлений для канала
8. **Действия внизу**:
   - Leave Channel (красная кнопка)
   - Archive Channel (для админов)

---

## План реализации

### Этап 1: Domain Layer

#### 1.1. Создать сущность `ChannelStats`
**Файл:** `lib/domain/entities/channel_stats.dart`

```dart
class ChannelStats extends Equatable {
  final String channelId;
  final int memberCount;
  final int guestCount;
  final int pinnedPostCount;

  const ChannelStats({
    required this.channelId,
    required this.memberCount,
    this.guestCount = 0,
    this.pinnedPostCount = 0,
  });

  @override
  List<Object?> get props => [channelId, memberCount, guestCount, pinnedPostCount];
}
```

#### 1.2. Создать сущность `ChannelMember`
**Файл:** `lib/domain/entities/channel_member.dart`

```dart
class ChannelMember extends Equatable {
  final String channelId;
  final String userId;
  final String roles;
  final int msgCount;
  final int mentionCount;
  final int lastViewedAt;

  // ... props
}
```

#### 1.3. Расширить `ChannelRepository`
**Файл:** `lib/domain/repositories/channel_repository.dart`

Добавить методы:
```dart
Future<Either<Failure, ChannelStats>> getChannelStats(String channelId);
Future<Either<Failure, List<ChannelMember>>> getChannelMembers(String channelId, {int page = 0, int perPage = 60});
Future<Either<Failure, void>> leaveChannel(String channelId, String userId);
Future<Either<Failure, Channel>> updateChannel(String channelId, {String? header, String? purpose, String? displayName});
```

### Этап 2: Data Layer

#### 2.1. Модели
**Файл:** `lib/data/models/channel_stats_model.dart`

```dart
class ChannelStatsModel extends ChannelStats {
  factory ChannelStatsModel.fromJson(Map<String, dynamic> json) {
    return ChannelStatsModel(
      channelId: json['channel_id'],
      memberCount: json['member_count'] ?? 0,
      guestCount: json['guest_count'] ?? 0,
      pinnedPostCount: json['pinnedpost_count'] ?? 0,
    );
  }
}
```

**Файл:** `lib/data/models/channel_member_model.dart`
— Аналогичный DTO с `fromJson`.

#### 2.2. Расширить `ChannelRemoteDataSource`
**Файл:** `lib/data/datasources/remote/channel_remote_datasource.dart`

Добавить методы:
```dart
/// GET /channels/{id}/stats
Future<ChannelStatsModel> getChannelStats(String channelId);

/// GET /channels/{id}/members?page=X&per_page=Y
Future<List<ChannelMemberModel>> getChannelMembers(String channelId, {int page = 0, int perPage = 60});

/// DELETE /channels/{id}/members/{userId}
Future<void> leaveChannel(String channelId, String userId);

/// PUT /channels/{id}
Future<ChannelModel> updateChannel(String channelId, Map<String, dynamic> body);
```

#### 2.3. Добавить API эндпоинты
**Файл:** `lib/core/network/api_endpoints.dart`

```dart
static String channelStats(String id) => '/channels/$id/stats';
// channelMembers уже есть
// Для leave: используем существующий channelMember(channelId, userId) с методом DELETE
```

#### 2.4. Реализовать в `ChannelRepositoryImpl`
**Файл:** `lib/data/repositories/channel_repository_impl.dart`

Реализовать новые методы. `getChannelStats` — только онлайн (кеширование не обязательно на первом этапе).

### Этап 3: Presentation Layer — BLoC

#### 3.1. Создать `ChannelInfoCubit`
**Файл:** `lib/presentation/screens/channel_info/channel_info_cubit.dart`

```dart
// States
abstract class ChannelInfoState {}
class ChannelInfoInitial extends ChannelInfoState {}
class ChannelInfoLoading extends ChannelInfoState {}
class ChannelInfoLoaded extends ChannelInfoState {
  final Channel channel;
  final ChannelStats stats;
  final List<User> members;  // первые N для превью
}
class ChannelInfoError extends ChannelInfoState { final String message; }

// Cubit
class ChannelInfoCubit extends Cubit<ChannelInfoState> {
  final ChannelRepository channelRepository;
  final UserRepository userRepository;

  Future<void> loadChannelInfo(String channelId);
  Future<void> leaveChannel(String channelId, String userId);
  Future<void> toggleMute(String channelId, String userId, bool isMuted);
}
```

Cubit загружает параллельно:
- `getChannel(channelId)` — актуальные данные канала
- `getChannelStats(channelId)` — количество участников
- `getChannelMembers(channelId, page: 0, perPage: 5)` — первые 5 участников для превью аватаров

### Этап 4: Presentation Layer — UI

#### 4.1. Модифицировать AppBar в `ChatScreen`
**Файл:** `lib/presentation/screens/chat/chat_screen.dart`

Изменения:
- Сделать title кликабельным (`GestureDetector` или `InkWell`)
- Добавить подзаголовок с количеством участников (для не-DM каналов)
- По тапу — навигация на `ChannelInfoScreen`

```dart
// Было:
title: Text(widget.channelName)

// Станет:
title: GestureDetector(
  onTap: () => context.push('/channel/${widget.channelId}/info'),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.channelName, style: ...),
      if (!isDirect)
        Text('$memberCount members', style: TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  ),
)
```

Для получения `memberCount` в AppBar:
- Загружать stats при инициализации `ChatBloc` или отдельным легковесным запросом
- Можно добавить поле `memberCount` в состояние `ChatBloc`, загружаемое при открытии чата

#### 4.2. Создать `ChannelInfoScreen`
**Файл:** `lib/presentation/screens/channel_info/channel_info_screen.dart`

Структура экрана:
```
+------------------------------------------+
|  <- Back                                  |
+------------------------------------------+
|                                          |
|   # channel-name                         |
|   Public Channel                         |
|                                          |
+------------------------------------------+
|  [Mute]  [Search]  [Pin]                 |  <- Быстрые действия
+------------------------------------------+
|                                          |
|  Header                                  |
|  Текст заголовка канала...               |
|                                          |
+------------------------------------------+
|  Purpose                                 |
|  Описание канала...                      |
|                                          |
+------------------------------------------+
|                                          |
|  Members (N)                         >   |  <- По тапу -> список членов
|  [ava1] [ava2] [ava3] [ava4] [ava5]     |
|                                          |
+------------------------------------------+
|  Pinned Messages                     >   |
+------------------------------------------+
|  Notification Preferences            >   |
+------------------------------------------+
|                                          |
|  [ Leave Channel ]                       |  <- Красная кнопка
|                                          |
+------------------------------------------+
```

#### 4.3. Создать `ChannelMembersScreen`
**Файл:** `lib/presentation/screens/channel_info/channel_members_screen.dart`

- Список участников с пагинацией (`ListView.builder`)
- Каждый элемент: аватар, имя, роль (admin/member), статус (online/offline)
- Поиск по участникам (опционально, можно во второй итерации)
- Тап на пользователя — навигация на профиль (`UserProfileScreen`)

#### 4.4. Виджеты
**Директория:** `lib/presentation/screens/channel_info/widgets/`

- `channel_info_header.dart` — иконка, название, тип канала
- `channel_quick_actions.dart` — горизонтальная панель быстрых действий
- `channel_members_preview.dart` — превью аватаров участников + счётчик
- `channel_info_section.dart` — переиспользуемая секция (header, purpose)
- `leave_channel_button.dart` — кнопка выхода с диалогом подтверждения

### Этап 5: Маршрутизация

#### 5.1. Добавить маршруты в `AppRouter`
**Файл:** `lib/core/router/app_router.dart`

```dart
GoRoute(
  path: '/channel/:channelId/info',
  builder: (context, state) {
    final channelId = state.pathParameters['channelId']!;
    final channel = state.extra as Channel?; // передаём для мгновенного отображения
    return ChannelInfoScreen(channelId: channelId, channel: channel);
  },
),
GoRoute(
  path: '/channel/:channelId/members',
  builder: (context, state) {
    final channelId = state.pathParameters['channelId']!;
    return ChannelMembersScreen(channelId: channelId);
  },
),
```

### Этап 6: Dependency Injection

#### 6.1. Регистрация в GetIt
**Файл:** `lib/core/di/injection.dart`

```dart
// Cubit
sl.registerFactory(() => ChannelInfoCubit(
  channelRepository: sl(),
  userRepository: sl(),
));
```

### Этап 7: Тестирование

#### 7.1. Unit-тесты
- `test/models/channel_stats_model_test.dart` — парсинг JSON
- `test/models/channel_member_model_test.dart` — парсинг JSON
- `test/repositories/channel_repository_test.dart` — расширить существующие тесты новыми методами
- `test/cubits/channel_info_cubit_test.dart` — загрузка, ошибки, leave channel

#### 7.2. Интеграционные тесты
- `integration_test/scenarios/channel_info_test.dart` — полный flow:
  1. Открытие чата -> тап на шапку -> Channel Info экран
  2. Проверка отображения header, purpose, member count
  3. Тап на Members -> список участников
  4. Leave Channel -> диалог подтверждения

---

## Порядок реализации (приоритизация)

### Итерация 1 (MVP) — Количество участников в шапке + базовый Channel Info
1. `ChannelStats` entity + model + `fromJson`
2. API endpoint `getChannelStats` в RemoteDataSource
3. Метод `getChannelStats` в Repository
4. Отображение `memberCount` в AppBar ChatScreen
5. Базовый `ChannelInfoScreen` (название, header, purpose, member count)
6. Навигация: тап на шапку -> Channel Info
7. Unit-тесты для model и repository

### Итерация 2 — Список участников и действия
1. `ChannelMember` entity + model
2. API `getChannelMembers` с пагинацией
3. `ChannelMembersScreen` со списком
4. Quick actions (Mute/Unmute — переиспользовать существующий функционал)
5. Ссылка на Pinned Messages из Channel Info
6. Unit-тесты

### Итерация 3 — Управление каналом
1. API `leaveChannel` + `updateChannel`
2. Leave Channel с диалогом подтверждения
3. Редактирование header/purpose (для админов)
4. Интеграционные тесты

---

## Затрагиваемые файлы

### Новые файлы
| Файл | Описание |
|------|----------|
| `lib/domain/entities/channel_stats.dart` | Сущность статистики канала |
| `lib/domain/entities/channel_member.dart` | Сущность участника канала |
| `lib/data/models/channel_stats_model.dart` | DTO статистики |
| `lib/data/models/channel_member_model.dart` | DTO участника |
| `lib/presentation/screens/channel_info/channel_info_screen.dart` | Экран информации о канале |
| `lib/presentation/screens/channel_info/channel_info_cubit.dart` | Cubit для Channel Info |
| `lib/presentation/screens/channel_info/channel_members_screen.dart` | Экран списка участников |
| `lib/presentation/screens/channel_info/widgets/` | Виджеты экрана |
| `test/models/channel_stats_model_test.dart` | Тест модели |
| `test/cubits/channel_info_cubit_test.dart` | Тест Cubit |
| `integration_test/scenarios/channel_info_test.dart` | Интеграционный тест |

### Модифицируемые файлы
| Файл | Изменение |
|------|-----------|
| `lib/domain/repositories/channel_repository.dart` | Новые методы |
| `lib/data/repositories/channel_repository_impl.dart` | Реализация новых методов |
| `lib/data/datasources/remote/channel_remote_datasource.dart` | Новые API вызовы |
| `lib/core/network/api_endpoints.dart` | Эндпоинт `channelStats` |
| `lib/core/router/app_router.dart` | Маршруты channel info и members |
| `lib/core/di/injection.dart` | Регистрация ChannelInfoCubit |
| `lib/presentation/screens/chat/chat_screen.dart` | Кликабельная шапка + member count |
| `test/integration_runner_test.dart` | Импорт нового сценария |

---

## API Mattermost (справка)

### GET /api/v4/channels/{channel_id}/stats
Ответ:
```json
{
  "channel_id": "abc123",
  "member_count": 42,
  "guest_count": 2,
  "pinnedpost_count": 5
}
```

### GET /api/v4/channels/{channel_id}/members?page=0&per_page=60
Ответ (массив):
```json
[
  {
    "channel_id": "abc123",
    "user_id": "user1",
    "roles": "channel_user channel_admin",
    "last_viewed_at": 1700000000000,
    "msg_count": 150,
    "mention_count": 3,
    "notify_props": { "mark_unread": "all" },
    "last_update_at": 1700000000000
  }
]
```

### DELETE /api/v4/channels/{channel_id}/members/{user_id}
Покинуть канал. Ответ: 200 OK.

### PUT /api/v4/channels/{channel_id}
Тело запроса:
```json
{
  "id": "abc123",
  "header": "New header",
  "purpose": "New purpose"
}
```
