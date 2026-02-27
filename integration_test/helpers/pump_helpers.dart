import 'package:flutter_test/flutter_test.dart';

/// Extension-методы для WidgetTester в интеграционных тестах.
extension PumpHelpers on WidgetTester {
  /// Ждёт завершения анимаций и пересборки виджетов.
  /// Удобно после навигации или анимаций.
  Future<void> pumpAndSettle2({
    Duration duration = const Duration(milliseconds: 100),
    int maxAttempts = 50,
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      await pump(duration);
      if (!hasRunningAnimations) break;
    }
  }

  /// Прокачивает виджеты N раз с заданной длительностью.
  Future<void> pumpN(int count,
      {Duration duration = const Duration(milliseconds: 50)}) async {
    for (var i = 0; i < count; i++) {
      await pump(duration);
    }
  }

  /// Ждёт появления виджета с указанным текстом.
  Future<void> waitForText(
    String text, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(interval);
      if (find.text(text).evaluate().isNotEmpty) return;
    }
    // Если не нашли — pump ещё раз для финального assert
    await pump();
  }
}
