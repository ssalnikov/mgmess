# Тестирование

## Обзор

Проект использует стандартный стек тестирования Flutter:

| Пакет | Назначение |
|-------|------------|
| `flutter_test` | Базовый фреймворк тестирования |
| `bloc_test` | Декларативные тесты для BLoC/Cubit |
| `mocktail` | Мок-объекты (без кодогенерации) |

## Структура тестов

```
test/
├── models/                          # Unit-тесты моделей
│   ├── user_model_test.dart         # 9 тестов
│   ├── channel_model_test.dart      # 9 тестов
│   ├── post_model_test.dart         # 11 тестов
│   └── file_info_model_test.dart    # 9 тестов
├── blocs/                           # Unit-тесты BLoC
│   ├── auth_bloc_test.dart          # 6 тестов
│   ├── channels_bloc_test.dart      # 4 теста
│   └── chat_bloc_test.dart          # 6 тестов
├── repositories/                    # Unit-тесты репозиториев
│   └── auth_repository_test.dart    # 7 тестов
└── widget_test.dart                 # Unit-тесты утилит (WsEvent, DateFormatter) — 8 тестов
```

**Итого: 68 тестов**

## Запуск

```bash
# Все тесты
flutter test

# Конкретный файл
flutter test test/blocs/auth_bloc_test.dart

# С подробным выводом
flutter test --reporter expanded

# С покрытием
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
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

**AuthBloc:**
- Проверка сессии — успех, отсутствие сессии, ошибка API
- OAuth — успешная авторизация, ошибка сохранения токенов
- Logout

**ChannelsBloc:**
- Загрузка каналов — успех, ошибка
- Поиск по имени — фильтрация, сброс фильтра

**ChatBloc:**
- Загрузка сообщений — успех, ошибка
- Отправка сообщения (оптимистичное добавление)
- Удаление сообщения
- Пагинация — блокировка при `isLoadingMore` или `!hasMore`

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

**AuthRepositoryImpl:**
- `getCurrentUser` — успех (сохраняет userId), ошибка (возвращает Failure)
- `saveAuthTokens` — сохранение токена и CSRF
- `logout` — очистка хранилища даже при ошибке сервера
- `hasValidSession` — с токеном, без токена, с невалидным токеном

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

## Рекомендации по расширению

При добавлении новой функциональности:

1. **Модель** → тесты `fromJson`, `toJson`, вычисляемые свойства
2. **Репозиторий** → тесты успеха/ошибки для каждого метода
3. **BLoC** → тесты каждого Event с проверкой последовательности State
4. **Widget** → `pumpWidget` + проверка ключевых элементов UI (при необходимости)
