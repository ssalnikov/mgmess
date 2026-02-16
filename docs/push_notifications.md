# Push-уведомления (FCM)

## Обзор

MGMess использует **Firebase Cloud Messaging (FCM)** для доставки push-уведомлений на Android и iOS. Уведомления работают в двух режимах:

- **Foreground** — приложение открыто, но пользователь в другом канале → показывается локальное уведомление через `flutter_local_notifications`
- **Background / Terminated** — приложение в фоне или закрыто → уведомление доставляется через Firebase и отображается системой

## Архитектура

```
Firebase Console                Mattermost Server
      │                               │
      │ FCM push (background)         │ WebSocket event (foreground)
      ▼                               ▼
┌──────────────┐            ┌──────────────────┐
│ FirebaseMsg.  │            │  WebSocketBloc   │
│ (system tray) │            │  .wsEvents       │
└──────────────┘            └────────┬─────────┘
                                     │ NotificationWsEvent
                            ┌────────▼─────────┐
                            │ NotificationBloc  │
                            │ (фильтрация,      │
                            │  подавление)       │
                            └────────┬─────────┘
                                     │ showNotification()
                            ┌────────▼─────────┐
                            │ NotificationService│
                            │ (flutter_local_    │
                            │  notifications)    │
                            └──────────────────┘
```

### Компоненты

| Компонент | Файл | Описание |
|-----------|------|----------|
| `NotificationService` | `lib/core/notifications/notification_service.dart` | Инициализация FCM, запрос разрешений, показ локальных уведомлений |
| `NotificationChannels` | `lib/core/notifications/notification_channels.dart` | Идентификаторы Android notification channels |
| `NotificationBloc` | `lib/presentation/blocs/notification/notification_bloc.dart` | Глобальный BLoC: токен, фильтрация WS-событий, подавление активного канала |
| `NotificationRepository` | `lib/domain/repositories/notification_repository.dart` | Абстрактный контракт |
| `NotificationRepositoryImpl` | `lib/data/repositories/notification_repository_impl.dart` | Реализация с `Either<Failure, T>` |
| `NotificationRemoteDataSource` | `lib/data/datasources/remote/notification_remote_datasource.dart` | PUT device_id на сервер |

## Настройка Firebase

### Шаг 1: Создание проекта Firebase

1. Перейти в [Firebase Console](https://console.firebase.google.com/)
2. Нажать **Add project** (или использовать существующий)
3. Ввести имя проекта (например, `mgmess`)
4. Отключить Google Analytics (не нужен для push) или оставить — на ваш выбор
5. Нажать **Create project**

### Шаг 2: Добавление Android-приложения

1. На странице проекта Firebase нажать **Add app** → **Android**
2. Заполнить:
   - **Android package name**: `my.games.mgmess`
   - **App nickname**: `MGMess`
   - **Debug signing certificate SHA-1**: (опционально, для FCM не требуется)
3. Нажать **Register app**
4. Скачать файл `google-services.json`
5. Поместить его в: `android/app/google-services.json`

```
android/
├── app/
│   ├── google-services.json    ← сюда
│   ├── build.gradle.kts
│   └── src/
```

6. Нажать **Next** → **Next** → **Continue to console**

### Шаг 3: Добавление iOS-приложения

1. На странице проекта Firebase нажать **Add app** → **iOS**
2. Заполнить:
   - **Apple bundle ID**: `my.games.mgmess` (проверить в `ios/Runner.xcodeproj`)
   - **App nickname**: `MGMess`
3. Нажать **Register app**
4. Скачать файл `GoogleService-Info.plist`
5. Поместить в: `ios/Runner/GoogleService-Info.plist`

```
ios/
├── Runner/
│   ├── GoogleService-Info.plist    ← сюда
│   ├── Info.plist
│   └── AppDelegate.swift
```

6. **Важно**: добавить файл через Xcode:
   - Открыть `ios/Runner.xcworkspace` в Xcode
   - Перетащить `GoogleService-Info.plist` в Runner (отметить **Copy items if needed**)
7. Нажать **Next** → **Continue to console**

### Шаг 4: Настройка iOS Push Certificates

Для работы push на iOS нужен APNs-ключ:

1. Перейти в [Apple Developer](https://developer.apple.com/account/resources/authkeys/list)
2. Создать **Key** с **Apple Push Notifications service (APNs)**
3. Скачать `.p8`-файл
4. В Firebase Console → **Project Settings** → **Cloud Messaging** → **iOS app configuration**
5. Загрузить APNs Authentication Key (`.p8`):
   - **Key ID**: из Apple Developer
   - **Team ID**: из Apple Developer Account

### Шаг 5: Включение Push Notifications в Xcode

1. Открыть `ios/Runner.xcworkspace` в Xcode
2. Выбрать target **Runner**
3. Перейти на вкладку **Signing & Capabilities**
4. Нажать **+ Capability**
5. Добавить:
   - **Push Notifications**
   - **Background Modes** → отметить **Remote notifications**

## Настройка Mattermost-сервера

Для работы push-уведомлений через Firebase необходимо настроить Mattermost Push Notification Service (MPNS) или использовать прямую доставку FCM.

### Вариант A: Прямая регистрация device token (текущая реализация)

Приложение регистрирует FCM-токен на сервере Mattermost через:

```
PUT /api/v4/users/sessions/device_id
Content-Type: application/json
Authorization: Bearer <auth_token>

{"device_id": "android:<fcm_token>"}
```

Mattermost привязывает device_id к текущей сессии (определяется по auth token). При получении нового сообщения сервер отправит push через настроенный push notification service.

### Настройка push на сервере

В `config.json` Mattermost-сервера:

```json
{
  "EmailSettings": {
    "SendPushNotifications": true,
    "PushNotificationServer": "https://push-test.mattermost.com",
    "PushNotificationContents": "full",
    "PushNotificationBuffer": 1000
  }
}
```

Или через **System Console** → **Environment** → **Push Notification Server**:

| Параметр | Значение | Описание |
|----------|----------|----------|
| `SendPushNotifications` | `true` | Включить отправку push |
| `PushNotificationServer` | URL MPNS или `https://push-test.mattermost.com` | Сервер доставки push |
| `PushNotificationContents` | `full` / `generic` / `id_loaded` | Содержимое уведомления |

### Вариант B: Собственный MPNS

Для полного контроля можно развернуть свой [Mattermost Push Proxy](https://github.com/mattermost/mattermost-push-proxy):

1. Собрать и развернуть mattermost-push-proxy
2. В конфигурации push-proxy указать Firebase Server Key:
   ```json
   {
     "AndroidPushSettings": [
       {
         "Type": "android",
         "AndroidAPIKey": "<Firebase Server Key>"
       }
     ],
     "ApplePushSettings": [
       {
         "Type": "apple",
         "ApplePushCertPrivate": "<path_to_apns_cert.pem>",
         "ApplePushTopic": "my.games.mgmess"
       }
     ]
   }
   ```
3. Firebase Server Key можно получить в **Firebase Console** → **Project Settings** → **Cloud Messaging** → **Server key**
4. В Mattermost `config.json` указать URL своего push-proxy как `PushNotificationServer`

## Настройки уведомлений в приложении

Пользователь может настроить уведомления в **Profile** → **Notification Settings**:

| Настройка | Ключ SharedPreferences | Значения | По умолчанию |
|-----------|----------------------|----------|-------------|
| Включение push | `notification_enabled` | `true` / `false` | `true` |
| Фильтр | `notification_filter` | `all` / `mentions_dm` / `dm_only` | `all` |

### Фильтры

- **All new messages** (`all`) — уведомления обо всех сообщениях во всех каналах
- **Mentions & direct messages** (`mentions_dm`) — только @упоминания и личные сообщения (DM/GM)
- **Direct messages only** (`dm_only`) — только прямые и групповые сообщения

### Подавление уведомлений

Уведомление **не показывается** если:
- Сообщение от текущего пользователя (собственные сообщения)
- Канал сообщения совпадает с активным (пользователь уже в этом чате)
- Push-уведомления отключены в настройках
- Фильтр не пропускает данный тип сообщения

## Жизненный цикл токена

```
AuthAuthenticated
      │
      ▼
NotificationInit(userId)
      │
      ├─ requestPermission()
      ├─ getToken() → FCM token
      ├─ PUT /users/sessions/device_id → регистрация на сервере
      └─ подписка на onTokenRefresh
              │
              ▼ (при обновлении токена)
      NotificationTokenRefreshed
              │
              └─ PUT /users/sessions/device_id → обновление на сервере

AuthUnauthenticated
      │
      ▼
NotificationLogout
      │
      ├─ PUT /users/sessions/device_id → {"device_id": ""} (снятие регистрации)
      └─ очистка состояния
```

## Проверка работоспособности

### 1. Проверить наличие конфигов Firebase

```bash
# Android
ls android/app/google-services.json

# iOS
ls ios/Runner/GoogleService-Info.plist
```

Если файлы отсутствуют — приложение запустится, но push будет отключён (в логах: `Firebase not configured, push notifications disabled`).

### 2. Проверить регистрацию токена

В логах приложения при авторизации должно быть:
```
NotificationReady(token: <fcm_token>, enabled: true)
```

### 3. Проверить регистрацию на сервере

```bash
# Получить текущие сессии пользователя
curl -H "Authorization: Bearer <token>" \
  https://mm.my.games/api/v4/users/me/sessions

# В ответе должен быть device_id: "android:<fcm_token>"
```

### 4. Отправить тестовое push-уведомление

```bash
# Через Firebase Console:
# Cloud Messaging → Send your first message → указать FCM-токен
```

### 5. Проверить фоновое уведомление

1. Авторизоваться в приложении
2. Свернуть приложение
3. Отправить сообщение пользователю из другого клиента (веб/десктоп)
4. Должно появиться системное уведомление

## Безопасность

- `google-services.json` и `GoogleService-Info.plist` **не должны** коммититься в репозиторий (добавить в `.gitignore`)
- FCM-токен привязан к конкретному устройству и приложению
- При logout токен снимается с сессии Mattermost (`device_id: ""`)
- APNs-ключ (`.p8`) хранить в безопасном месте, не коммитить

## Troubleshooting

| Проблема | Причина | Решение |
|----------|---------|---------|
| Push не работают совсем | Нет конфигов Firebase | Добавить `google-services.json` / `GoogleService-Info.plist` |
| Push не приходят в фоне | Не настроен push-proxy на сервере | Настроить `PushNotificationServer` в Mattermost |
| Push не приходят на iOS | Нет APNs-ключа в Firebase | Загрузить `.p8` в Firebase Console |
| Push приходят, но без текста | `PushNotificationContents: "generic"` | Изменить на `"full"` в config.json |
| Двойные уведомления | FCM push + WS local notification | Нормальное поведение: FCM для фона, WS для foreground |
| Уведомление не показывается в открытом канале | Active channel suppression | Ожидаемое поведение: уведомления подавляются для текущего канала |
| `Firebase not configured` в логах | Нет google-services.json | Приложение работает без push, нужно добавить конфиг |
