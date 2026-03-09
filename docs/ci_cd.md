# CI/CD Pipeline

## Обзор

MGMess использует **GitLab CI/CD** для автоматизации сборки, тестирования и деплоя. Конфигурация — `.gitlab-ci.yml` в корне репозитория.

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ analyze  │───→│   test   │───→│  build   │───→│  deploy  │
│          │    │          │    │          │    │ (manual) │
│ • lint   │    │ • unit   │    │ • APK    │    │ • Firebase│
│ • format │    │ • integ  │    │ • iOS    │    │  App Dist │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

## Стейджи

### 1. Analyze

| Job | Команда | Когда |
|-----|---------|-------|
| `lint` | `flutter analyze --no-fatal-infos` | MR + master |
| `format_check` | `dart format --set-exit-if-changed lib/ test/` | MR + master |

- `--no-fatal-infos` — info-уровень (стилевые подсказки) не блокирует пайплайн
- Формат проверяется, но не применяется автоматически

### 2. Test

| Job | Команда | Артефакты |
|-----|---------|-----------|
| `unit_tests` | `flutter test test/ --reporter expanded --coverage` | `coverage/lcov.info` (30 дней) |
| `integration_tests` | `flutter test test/integration_runner_test.dart --reporter expanded` | — |

- Coverage report в формате cobertura отображается в GitLab MR
- Regex для парсинга покрытия: `/lines\.+: (\d+\.\d+)%/`
- Интеграционные тесты запускаются как widget-тесты (без устройства)

### 3. Build

| Job | Команда | Артефакты | Когда |
|-----|---------|-----------|-------|
| `build_apk` | `flutter build apk --release --split-per-abi` | `*.apk` (14 дней) | master + tags |
| `build_ios` | `flutter build ios --release --no-codesign` | `Runner.app` (14 дней) | master + tags |

- APK собирается с `--split-per-abi` (отдельные APK для arm64-v8a, armeabi-v7a, x86_64)
- iOS собирается без подписи (`--no-codesign`) — подписывание выполняется на этапе деплоя
- iOS job имеет `allow_failure: true` — требует macOS runner (тег `macos`)

### 4. Deploy

| Job | Команда | Когда |
|-----|---------|-------|
| `deploy_firebase` | Firebase App Distribution | Tags (manual) |

- Запуск **вручную** (кнопка в GitLab UI)
- Требует переменную `FIREBASE_APP_ID` в CI/CD settings
- Группа тестировщиков: `testers`

## Переменные окружения

| Переменная | Описание | Где настроить |
|------------|----------|---------------|
| `FLUTTER_VERSION` | Версия Flutter SDK | `.gitlab-ci.yml` (default: 3.41.0) |
| `FIREBASE_APP_ID` | ID приложения Firebase | GitLab > Settings > CI/CD > Variables |

## Кеширование

Кеш привязан к `pubspec.lock` — при изменении зависимостей кеш пересоздаётся.

```yaml
cache:
  key:
    files:
      - pubspec.lock
  paths:
    - .dart_tool/
    - .packages
    - build/
```

## Правила запуска

| Событие | analyze | test | build | deploy |
|---------|---------|------|-------|--------|
| Merge Request | ✅ | ✅ | — | — |
| Push в master | ✅ | ✅ | ✅ | — |
| Создание тега | — | — | ✅ | ✅ (manual) |

## Docker-образ

Используется `ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION}` — образ с предустановленным Flutter SDK, Android SDK и Dart.

## Локальная проверка

Перед пушем можно локально проверить то же, что проверяет CI:

```bash
# Lint (то же что lint job)
flutter analyze --no-fatal-infos

# Format (то же что format_check job)
dart format --set-exit-if-changed lib/ test/

# Unit tests (то же что unit_tests job)
flutter test test/ --reporter expanded --coverage

# Integration tests (то же что integration_tests job)
flutter test test/integration_runner_test.dart --reporter expanded

# Build APK (то же что build_apk job)
flutter build apk --release --split-per-abi
```

## Расширение

### Добавить code signing для iOS

```yaml
build_ios_signed:
  extends: .flutter_base
  stage: build
  tags:
    - macos
  before_script:
    - flutter pub get
    - security import $IOS_CERTIFICATE -P $IOS_CERT_PASSWORD -A -t cert
    - mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    - cp $IOS_PROVISIONING_PROFILE ~/Library/MobileDevice/Provisioning\ Profiles/
  script:
    - flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

### Добавить автоматическую проверку размера APK

```yaml
apk_size_check:
  extends: .flutter_base
  stage: build
  script:
    - flutter build apk --release
    - APK_SIZE=$(stat -f%z build/app/outputs/flutter-apk/app-release.apk)
    - echo "APK size: $((APK_SIZE / 1024 / 1024)) MB"
    - '[ $APK_SIZE -lt 52428800 ] || (echo "APK exceeds 50MB limit!" && exit 1)'
```
