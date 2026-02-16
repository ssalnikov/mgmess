# MGMess — Мобильный клиент Mattermost для MyGames

## Содержание

- [Обзор проекта](#обзор-проекта)
- [Требования](#требования)
- [Быстрый старт](#быстрый-старт)
- [Документация](#документация)

## Обзор проекта

MGMess — нативное мобильное приложение (iOS + Android) на Flutter, реализующее клиент корпоративного Mattermost-сервера MyGames. Приложение поддерживает:

- Авторизацию через GitLab OAuth
- Просмотр каналов с бейджами непрочитанных сообщений
- Обмен сообщениями в реальном времени (WebSocket)
- Отправку и просмотр файлов/изображений
- Сохраненные сообщения (flagged posts)
- Упоминания (@mentions)
- Read receipts (MyGames seens) — кастомное расширение бэкенда
- Push-уведомления (Firebase Cloud Messaging)
- Профиль пользователя с редактированием

## Требования

| Компонент | Версия |
|-----------|--------|
| Flutter SDK | 3.41+ |
| Dart SDK | 3.11+ |
| iOS | 13.0+ |
| Android | API 21+ (Android 5.0) |
| Mattermost Server | с расширениями MyGames (seens) |

## Быстрый старт

```bash
# Клонировать репозиторий
cd /mattermost/mgmess

# Установить зависимости
flutter pub get

# Запуск на устройстве/эмуляторе
flutter run

# Запуск тестов
flutter test

# Статический анализ
flutter analyze

# Сборка APK
flutter build apk --release

# Сборка iOS
flutter build ios --release
```

## Документация

| Документ | Описание |
|----------|----------|
| [Архитектура](architecture.md) | Clean Architecture, структура проекта, слои |
| [Аутентификация](authentication.md) | GitLab OAuth flow для мобильных клиентов |
| [WebSocket](websocket.md) | Real-time подключение, события, reconnect |
| [API](api.md) | REST-эндпоинты Mattermost API v4 |
| [State Management](state_management.md) | BLoC-паттерн, список блоков, потоки данных |
| [Тестирование](testing.md) | Стратегия, структура тестов, запуск |
| [Push-уведомления](push_notifications.md) | Firebase Cloud Messaging: настройка, конфигурация, troubleshooting |
| [Настройка сервера](server_setup.md) | Конфигурация бэкенда для работы с приложением |
