# Настройка сервера

## Обзор

Для корректной работы мобильного клиента MGMess необходимо внести изменения в конфигурацию Mattermost-сервера.

## 1. Регистрация custom URL scheme

Добавить `mgmess://` в список разрешённых мобильных URL-схем.

### Через config.json

Отредактировать файл `config.json` на сервере:

```json
{
  "NativeAppSettings": {
    "AppCustomURLSchemes": [
      "mgmess://"
    ]
  }
}
```

### Через System Console

1. Перейти в **System Console** → **Environment** → **Custom URL Schemes**
2. Добавить `mgmess://`
3. Сохранить и перезапустить сервер

### Зачем это нужно

Сервер валидирует `redirect_to` параметр при OAuth-авторизации (функция `IsValidMobileAuthRedirectURL` в `server/channels/web/oauth.go`). Если URL-схема не зарегистрирована — сервер отклонит запрос на авторизацию.

## 2. Проверка OAuth GitLab

Убедиться, что GitLab OAuth настроен:

### В config.json

```json
{
  "GitLabSettings": {
    "Enable": true,
    "Id": "<GitLab Application ID>",
    "Secret": "<GitLab Application Secret>",
    "Scope": "read_user",
    "AuthEndpoint": "https://gitlab.my.games/oauth/authorize",
    "TokenEndpoint": "https://gitlab.my.games/oauth/token",
    "UserAPIEndpoint": "https://gitlab.my.games/api/v4/user",
    "DiscoveryEndpoint": ""
  }
}
```

### В GitLab

Убедиться, что OAuth Application в GitLab имеет:
- **Redirect URI**: `https://mm.my.games/signup/gitlab/complete`
- **Scopes**: `read_user`

## 3. Проверка CORS (если необходимо)

Если мобильный клиент обращается напрямую к API (без прокси), проверить настройки CORS:

```json
{
  "ServiceSettings": {
    "AllowCorsFrom": "*"
  }
}
```

В продакшене рекомендуется указывать конкретные origins вместо `*`.

## 4. Проверка WebSocket

WebSocket должен быть доступен по адресу:
```
wss://mm.my.games/api/v4/websocket
```

Если используется reverse proxy (nginx), убедиться в проксировании WebSocket:

```nginx
location /api/v4/websocket {
    proxy_pass http://mattermost_backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 600s;
}
```

## 5. Seens (MyGames расширение)

Убедиться, что кастомные эндпоинты seens доступны:

```
GET /api/v4/channels/{id}/seens
GET /api/v4/posts/{id}/seens
```

А также что WebSocket-события `channel_seens_updated` и `thread_seens_updated` отправляются.

Константа для мобильного маркинга:
```go
WebsocketMessagePropertySeensMark = "its_need_to_mark_seen_for_mobile"
```

## 6. Лимиты загрузки файлов

Проверить настройки максимального размера файла:

```json
{
  "FileSettings": {
    "EnableFileAttachments": true,
    "MaxFileSize": 104857600
  }
}
```

`MaxFileSize` в байтах (100 МБ в примере).

## 7. Верификация

После настройки проверить:

1. **OAuth**: открыть в браузере:
   ```
   https://mm.my.games/oauth/gitlab/mobile_login?redirect_to=mgmess://oauth/callback
   ```
   Должна показаться страница авторизации GitLab.

2. **API**: выполнить запрос с токеном:
   ```bash
   curl -H "Authorization: Bearer <token>" https://mm.my.games/api/v4/users/me
   ```
   Должен вернуться JSON с данными пользователя.

3. **WebSocket**: подключиться через wscat:
   ```bash
   wscat -c wss://mm.my.games/api/v4/websocket
   > {"seq":1,"action":"authentication_challenge","data":{"token":"<token>"}}
   ```
   Должно прийти событие `hello`.

4. **Seens**:
   ```bash
   curl -H "Authorization: Bearer <token>" https://mm.my.games/api/v4/channels/<id>/seens
   ```
   Должен вернуться JSON со списком пользователей.
