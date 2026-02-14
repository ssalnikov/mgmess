# REST API

## Обзор

Приложение использует Mattermost REST API v4. Базовый URL:

```
https://mm.my.games/api/v4
```

Все запросы проходят через `ApiClient` (Dio) с автоматической подстановкой заголовков авторизации.

## Заголовки

```http
Authorization: Bearer <MMAUTHTOKEN>
X-CSRF-Token: <MMCSRF>
Content-Type: application/json
```

Для загрузки файлов: `Content-Type: multipart/form-data`.

## Interceptors

| Interceptor | Описание |
|-------------|----------|
| `_AuthInterceptor` | Подставляет `Authorization` и `X-CSRF-Token` в каждый запрос. При 401 — очищает хранилище токенов |
| `_RetryInterceptor` | Повторяет запросы при 5xx ошибках (до 3 попыток с линейным backoff) |
| `_LoggingInterceptor` | Логирует метод, путь и статус каждого запроса |

## Эндпоинты

### Аутентификация

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/users/me` | Получить текущего пользователя (проверка сессии) |
| POST | `/users/logout` | Выход из системы |

OAuth авторизация проходит через браузер, а не через API напрямую. См. [Аутентификация](authentication.md).

### Пользователи

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/users/{id}` | Получить пользователя по ID |
| GET | `/users/{id}/image` | Аватар пользователя (изображение) |
| POST | `/users/ids` | Получить список пользователей по массиву ID |
| PUT | `/users/{id}/patch` | Обновить профиль пользователя |
| POST | `/users/status/ids` | Получить статусы пользователей (online/away/dnd/offline) |

#### Пример: обновление профиля

```http
PUT /api/v4/users/{id}/patch
```
```json
{
  "first_name": "Иван",
  "last_name": "Петров",
  "nickname": "ivan",
  "position": "Разработчик"
}
```

### Команды

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/users/me/teams` | Получить команды текущего пользователя |

### Каналы

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/users/{userId}/teams/{teamId}/channels` | Каналы пользователя в команде |
| GET | `/channels/{id}` | Информация о канале |
| GET | `/channels/{id}/members/{userId}` | Членство пользователя в канале (unread counts) |
| POST | `/channels/members/{userId}/view` | Пометить канал как прочитанный |
| POST | `/channels/direct` | Создать/получить DM канал |

#### Пример: пометить канал прочитанным

```http
POST /api/v4/channels/members/{userId}/view
```
```json
{
  "channel_id": "abc123"
}
```

#### Членство в канале (ответ)

```json
{
  "channel_id": "abc123",
  "user_id": "user1",
  "msg_count": 42,
  "mention_count": 3,
  "last_viewed_at": 1700000000000
}
```

Подсчёт непрочитанных: `unread = channel.total_msg_count - member.msg_count`.

### Сообщения (Posts)

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/channels/{id}/posts` | Получить сообщения канала |
| POST | `/posts` | Создать сообщение |
| GET | `/posts/{id}` | Получить сообщение по ID |
| DELETE | `/posts/{id}` | Удалить сообщение |
| GET | `/posts/{id}/thread` | Получить тред (ответы на сообщение) |
| GET | `/users/{id}/posts/flagged` | Сохранённые сообщения |
| POST | `/teams/{id}/posts/search` | Поиск сообщений |

#### Пагинация сообщений

```http
GET /api/v4/channels/{id}/posts?page=0&per_page=60
GET /api/v4/channels/{id}/posts?before={postId}&per_page=60
GET /api/v4/channels/{id}/posts?after={postId}&per_page=60
```

#### Формат ответа PostList

```json
{
  "order": ["post3", "post2", "post1"],
  "posts": {
    "post1": { "id": "post1", "message": "...", ... },
    "post2": { "id": "post2", "message": "...", ... },
    "post3": { "id": "post3", "message": "...", ... }
  }
}
```

`order` — ID сообщений в порядке от новых к старым. `posts` — словарь с полными объектами.

#### Создание сообщения

```http
POST /api/v4/posts
```
```json
{
  "channel_id": "abc123",
  "message": "Привет!",
  "root_id": "",
  "file_ids": ["file1", "file2"]
}
```

- `root_id` — ID родительского сообщения (для ответов в треде). Пустая строка для обычных сообщений.
- `file_ids` — массив ID предварительно загруженных файлов.

#### Поиск упоминаний

```http
POST /api/v4/teams/{teamId}/posts/search
```
```json
{
  "terms": "@username",
  "is_or_search": false
}
```

### Сохранённые сообщения (Preferences)

| Метод | Путь | Описание |
|-------|------|----------|
| PUT | `/users/{id}/preferences` | Сохранить сообщение (flag) |
| POST | `/users/{id}/preferences/delete` | Убрать из сохранённых (unflag) |

#### Flag (сохранить)

```http
PUT /api/v4/users/{id}/preferences
```
```json
[{
  "user_id": "user1",
  "category": "flagged_post",
  "name": "post123",
  "value": "true"
}]
```

#### Unflag (убрать из сохранённых)

```http
POST /api/v4/users/{id}/preferences/delete
```
```json
[{
  "user_id": "user1",
  "category": "flagged_post",
  "name": "post123"
}]
```

### Файлы

| Метод | Путь | Описание |
|-------|------|----------|
| POST | `/files` | Загрузить файл(ы) (multipart) |
| GET | `/files/{id}` | Скачать файл |
| GET | `/files/{id}/info` | Метаданные файла |
| GET | `/files/{id}/thumbnail` | Миниатюра (для изображений) |
| GET | `/files/{id}/preview` | Превью (для изображений) |

#### Загрузка файла

```http
POST /api/v4/files
Content-Type: multipart/form-data

channel_id: abc123
files: (binary data)
```

Ответ:
```json
{
  "file_infos": [{
    "id": "file1",
    "name": "photo.jpg",
    "extension": "jpg",
    "size": 1048576,
    "mime_type": "image/jpeg",
    "width": 1920,
    "height": 1080,
    "has_preview_image": true
  }]
}
```

После загрузки файла его `id` передаётся в `file_ids` при создании сообщения.

### Seens (MyGames — кастомные эндпоинты)

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/channels/{id}/seens` | Кто прочитал последнее сообщение канала |
| GET | `/posts/{id}/seens` | Кто прочитал конкретное сообщение |

#### Формат ответа

```json
{
  "users": [
    {
      "@odata.type": "user",
      "@odata.id": "user1",
      "first_name": "Иван",
      "last_name": "Петров",
      "user_name": "ipetrov",
      "seen_at": 1700000000000
    }
  ]
}
```

### Реакции

| Метод | Путь | Описание |
|-------|------|----------|
| POST | `/reactions` | Добавить реакцию |
| GET | `/posts/{id}/reactions` | Получить реакции на сообщение |

## Обработка ошибок

### Формат ошибки API

```json
{
  "id": "api.user.login.invalid_credentials",
  "message": "Invalid credentials",
  "status_code": 401
}
```

### Коды ошибок

| Код | Описание | Действие |
|-----|----------|----------|
| 401 | Не авторизован (токен истёк) | Очистка хранилища → экран авторизации |
| 403 | Нет доступа к ресурсу | Показать ошибку |
| 404 | Ресурс не найден | Показать ошибку |
| 429 | Rate limit | Повтор с задержкой |
| 5xx | Ошибка сервера | Автоматический retry (до 3 раз) |

## Таймауты

| Параметр | Значение |
|----------|----------|
| Connect timeout | 30 секунд |
| Receive timeout | 30 секунд |
| Send timeout | 30 секунд |
| Max retries (5xx) | 3 |
| Retry delay | 1с, 2с, 3с (линейный) |
