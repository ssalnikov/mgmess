import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  group('Search Channels', () {
    testWidgets('ввод текста в поиск → фильтрация каналов', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');

      // Оба канала видны
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Flutter Development'), findsOneWidget);

      // Вводим текст в поле поиска
      final searchField =
          find.widgetWithText(TextField, 'Search channels...');
      await tester.enterText(searchField, 'Flutter');
      await tester.pump();

      // General отфильтрован, Flutter Development остался
      expect(find.text('Flutter Development'), findsOneWidget);
      expect(find.text('General'), findsNothing);
    });

    testWidgets('очистка поиска → все каналы возвращаются', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');

      // Вводим текст в поле поиска
      final searchField =
          find.widgetWithText(TextField, 'Search channels...');
      await tester.enterText(searchField, 'Flutter');
      await tester.pump();

      expect(find.text('General'), findsNothing);

      // Очищаем поиск
      await tester.enterText(searchField, '');
      await tester.pump();

      // Все каналы снова видны
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Flutter Development'), findsOneWidget);
    });

    testWidgets('поиск без результатов → пустой список', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');

      final searchField =
          find.widgetWithText(TextField, 'Search channels...');
      await tester.enterText(searchField, 'NonExistentChannel');
      await tester.pump();

      // Ни один канал не виден
      expect(find.text('General'), findsNothing);
      expect(find.text('Flutter Development'), findsNothing);
    });
  });
}
