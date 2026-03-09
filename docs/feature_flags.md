# Feature Flags

## Обзор

Feature flags позволяют включать/выключать функциональность без выпуска нового билда. Реализация — `lib/core/feature_flags/feature_flags.dart`.

### Зачем

1. **Kill switch** — если фича ломает приложение, можно выключить удалённо за секунды (без ожидания review в App Store)
2. **Постепенный раскат** — включить для группы тестировщиков, проверить, раскатить на всех
3. **Разделение деплоя и релиза** — можно мержить недоделанную фичу за флагом
4. **A/B тестирование** — разный UI для разных групп

## Архитектура

```
┌─────────────────────────────────────────────┐
│          Порядок разрешения флага            │
│                                             │
│  1. Local override  (setOverride)           │
│     ↓ (если нет)                            │
│  2. Remote config   (applyRemoteConfig)     │
│     ↓ (если нет)                            │
│  3. Compiled default (FeatureFlag.default)   │
└─────────────────────────────────────────────┘
```

Local override всегда побеждает — это позволяет тестировщикам и разработчикам принудительно включить/выключить фичу на своём устройстве.

## Определённые флаги

| Флаг | Default | Описание |
|------|---------|----------|
| `linkPreview` | `true` | OpenGraph preview ссылок в чате |
| `voiceMessages` | `false` | Запись и воспроизведение голосовых сообщений |
| `aiSummarization` | `false` | AI-краткое содержание непрочитанных |
| `crashReporting` | `true` | Sentry crash reporting |
| `analytics` | `true` | Сбор аналитики использования |
| `onboarding` | `true` | Показ онбординга новым пользователям |
| `biometricLock` | `true` | Face ID / Touch ID блокировка |
| `videoCalls` | `false` | Кнопка видеозвонков (Jitsi) |

## Использование в коде

### Проверка флага

```dart
import 'package:mgmess/core/feature_flags/feature_flags.dart';
import 'package:mgmess/core/di/injection.dart';

final flags = sl<FeatureFlagService>();

// Способ 1: метод
if (flags.isEnabled(FeatureFlag.linkPreview)) {
  // показать link preview
}

// Способ 2: оператор []
if (flags[FeatureFlag.voiceMessages]) {
  // показать кнопку микрофона
}
```

### Добавление нового флага

1. Добавить значение в `enum FeatureFlag`:

```dart
enum FeatureFlag {
  // ... существующие флаги

  /// Описание нового флага.
  myNewFeature(defaultValue: false);

  // ...
}
```

2. Использовать в коде:

```dart
if (sl<FeatureFlagService>().isEnabled(FeatureFlag.myNewFeature)) {
  // новая фича
}
```

Больше ничего не нужно — флаг автоматически появится в системе с дефолтным значением.

### Установка override (для тестирования)

```dart
final flags = sl<FeatureFlagService>();

// Включить фичу принудительно
await flags.setOverride(FeatureFlag.voiceMessages, true);

// Убрать override (вернуться к remote/default)
await flags.clearOverride(FeatureFlag.voiceMessages);

// Проверить наличие override
final hasOverride = await flags.hasOverride(FeatureFlag.voiceMessages);
```

### Remote config (от сервера)

```dart
// Применить конфиг с сервера (например, при запуске или по расписанию)
await flags.applyRemoteConfig({
  'voiceMessages': true,
  'aiSummarization': false,
});
```

Remote config можно загружать с любого бэкенда:

```dart
// Пример: загрузка с Mattermost-сервера (кастомный эндпоинт)
final response = await apiClient.dio.get('/api/v4/config/client?format=old');
final config = <String, bool>{};
for (final flag in FeatureFlag.values) {
  final key = 'FeatureFlag${flag.name}';
  if (response.data[key] != null) {
    config[flag.name] = response.data[key] == 'true';
  }
}
await flags.applyRemoteConfig(config);
```

## Хранение

| Тип | SharedPreferences ключ | Пример |
|-----|----------------------|--------|
| Local override | `ff_local_<flagName>` | `ff_local_voiceMessages` |
| Remote config | `ff_remote_<flagName>` | `ff_remote_voiceMessages` |

Все значения — `bool`. Хранятся между перезапусками приложения.

## Отладка

```dart
final flags = sl<FeatureFlagService>();

// Получить все текущие значения
final all = flags.getAllFlags();
print(all);
// {linkPreview: true, voiceMessages: false, aiSummarization: false, ...}

// Сбросить все overrides и remote config
await flags.resetAll();
```

## DI и инициализация

```dart
// injection.dart — регистрация
sl.registerLazySingleton(() => FeatureFlagService());

// main.dart — инициализация (до использования!)
await sl<FeatureFlagService>().init();
```

`init()` загружает сохранённые значения из `SharedPreferences`. Вызывать **до** любого обращения к `isEnabled()`.

## Тестирование

### В unit-тестах

```dart
SharedPreferences.setMockInitialValues({});
final service = FeatureFlagService();
await service.init();

expect(service.isEnabled(FeatureFlag.linkPreview), isTrue);
expect(service.isEnabled(FeatureFlag.voiceMessages), isFalse);
```

### В интеграционных тестах

`FeatureFlagService` регистрируется в `test_di.dart` с пустыми SharedPreferences — все флаги имеют дефолтные значения.

### Покрытие тестами (`test/core/feature_flags_test.dart`)

11 тестов:
- Дефолтные значения для каждого флага
- Оператор `[]` работает как `isEnabled`
- Local override применяется и очищается
- Remote config применяется
- Local override побеждает remote config
- `clearOverride` возвращает remote config
- `getAllFlags` возвращает все флаги
- `hasOverride` корректно определяет наличие
- `resetAll` сбрасывает всё к дефолтам
- Персистенция между перезагрузками
