# Аутентификация

## Обзор

MGMess использует **GitLab OAuth** для авторизации пользователей — тот же механизм, что и веб-версия Mattermost. Для мобильных клиентов применяется custom URL scheme `mgmess://` для перехвата OAuth-callback.

## OAuth Flow

```
┌──────────┐    1. Открыть браузер     ┌──────────┐
│          │ ──────────────────────────>│          │
│  MGMess  │                           │ Браузер  │
│  (App)   │    6. Deep link callback  │          │
│          │ <─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │          │
└──────────┘                           └──────────┘
                                           │ 2. GET /oauth/gitlab/mobile_login
                                           ▼
                                     ┌──────────┐
                                     │Mattermost│ 3. Redirect → GitLab
                                     │  Server  │ ─────────────────────>┌────────┐
                                     │          │                       │ GitLab │
                                     │          │ 4. OAuth callback     │        │
                                     │          │ <─────────────────────│        │
                                     └──────────┘                       └────────┘
                                           │ 5. Redirect → mgmess://oauth/callback
                                           │    ?MMAUTHTOKEN=xxx&MMCSRF=yyy
                                           ▼
                                     (браузер открывает deep link)
```

### Шаги подробно

1. **Пользователь нажимает "Войти через GitLab"** — приложение открывает системный браузер:
   ```
   GET https://mm.my.games/oauth/gitlab/mobile_login?redirect_to=mgmess://oauth/callback
   ```

2. **Сервер Mattermost** (`server/channels/web/oauth.go`, функция `mobileLoginWithOAuth`) проверяет `redirect_to` URL и перенаправляет пользователя на GitLab для авторизации.

3. **GitLab** показывает страницу авторизации. Пользователь вводит учётные данные.

4. **GitLab** перенаправляет обратно на Mattermost с authorization code.

5. **Mattermost** обменивает code на токен, создаёт сессию и формирует redirect:
   ```
   mgmess://oauth/callback?MMAUTHTOKEN=<token>&MMCSRF=<csrf>
   ```

6. **Приложение** перехватывает deep link через `app_links`, извлекает токены и сохраняет их.

## Реализация в коде

### Custom URL Scheme

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="mgmess"/>
</intent-filter>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>my.games.mgmess</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>mgmess</string>
        </array>
    </dict>
</array>
```

### Обработка deep link (AuthScreen)

```dart
_appLinks.uriLinkStream.listen((uri) {
  if (uri.scheme == AppConfig.callbackScheme) {
    final token = uri.queryParameters['MMAUTHTOKEN'];
    final csrf = uri.queryParameters['MMCSRF'];
    if (token != null && token.isNotEmpty) {
      context.read<AuthBloc>().add(
        AuthOAuthCompleted(token: token, csrfToken: csrf),
      );
    }
  }
});
```

### Хранение токенов

Токены сохраняются в **flutter_secure_storage**:
- iOS: Keychain
- Android: EncryptedSharedPreferences

```dart
class SecureStorage {
  static const _keyToken = 'mm_auth_token';
  static const _keyCsrf = 'mm_csrf_token';
  static const _keyUserId = 'mm_user_id';
  // ...
}
```

### Авторизация запросов

Все HTTP-запросы автоматически получают заголовки через `_AuthInterceptor`:

```
Authorization: Bearer <MMAUTHTOKEN>
X-CSRF-Token: <MMCSRF>
```

### Auto-login

При запуске приложения `AuthBloc` проверяет наличие активной сессии:

1. Проверяет наличие токена в SecureStorage
2. Выполняет `GET /api/v4/users/me` для валидации
3. Если сессия валидна — переходит к списку каналов
4. Если нет — показывает экран авторизации

## AuthBloc — события и состояния

### События

| Событие | Описание |
|---------|----------|
| `AuthCheckSession` | Проверка существующей сессии при запуске |
| `AuthOAuthCompleted` | OAuth завершён успешно (получены токены) |
| `AuthLogoutRequested` | Пользователь нажал "Выйти" |

### Состояния

| Состояние | Описание |
|-----------|----------|
| `AuthInitial` | Начальное состояние |
| `AuthLoading` | Идёт проверка сессии или авторизация |
| `AuthAuthenticated` | Пользователь авторизован (содержит `User`) |
| `AuthUnauthenticated` | Сессия отсутствует или истекла |
| `AuthError` | Ошибка авторизации |

### Диаграмма переходов

```
AuthInitial
    │ AuthCheckSession
    ▼
AuthLoading
    ├─ сессия валидна ──> AuthAuthenticated
    └─ нет сессии ──────> AuthUnauthenticated
                              │ AuthOAuthCompleted
                              ▼
                          AuthLoading
                              ├─ успех ──> AuthAuthenticated
                              └─ ошибка ─> AuthError

AuthAuthenticated
    │ AuthLogoutRequested
    ▼
AuthUnauthenticated
```

## Настройка сервера

Для работы OAuth с мобильным клиентом необходимо добавить `mgmess://` в разрешённые URL-схемы на сервере. См. [Настройка сервера](server_setup.md).

## Обработка ошибок

- **401 Unauthorized**: `_AuthInterceptor` автоматически очищает хранилище токенов, что приводит к переходу на экран авторизации
- **Сетевая ошибка**: показывается сообщение об ошибке с кнопкой повторной попытки
- **Невалидный callback**: если deep link не содержит токен — он игнорируется
