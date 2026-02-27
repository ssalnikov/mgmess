import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:mgmess/app.dart';
import 'package:mgmess/core/di/injection.dart';

/// Patrol тест для OAuth через системный браузер.
///
/// Требует:
/// - Настроенный Patrol CLI: `dart pub global activate patrol_cli`
/// - Реальное устройство или эмулятор
/// - Запуск: `patrol test integration_test/patrol/oauth_browser_test.dart`
///
/// Этот тест взаимодействует с нативным UI (системный браузер),
/// поэтому не может быть запущен через `flutter test`.
void main() {
  patrolTest(
    'OAuth flow через системный браузер',
    ($) async {
      await initDependencies();
      await $.pumpWidgetAndSettle(const App());

      // Ожидаем AuthScreen
      expect($('MGMess'), findsOneWidget);
      expect($('Sign in with GitLab'), findsOneWidget);

      // Тапаем "Sign in with GitLab" — откроется системный браузер
      await $('Sign in with GitLab').tap();

      // Ожидаем переключения на нативный браузер
      // Patrol может взаимодействовать с нативным UI
      // Ожидаем страницу GitLab login
      await $.native.waitUntilVisible(
        Selector(textContains: 'GitLab'),
        timeout: const Duration(seconds: 15),
      );

      // Примечание: дальнейшее взаимодействие зависит от
      // конкретной конфигурации GitLab сервера.
      // В CI-среде можно использовать тестовый аккаунт.
    },
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 15),
    ),
  );
}
