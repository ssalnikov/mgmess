import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  group('Channel List', () {
    testWidgets('каналы загружаются и отображаются', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');

      expect(find.text('General'), findsOneWidget);
      expect(find.text('Flutter Development'), findsOneWidget);
    });

    testWidgets('тап по каналу → навигация в чат', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');

      // Тапаем по каналу General
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();

      // Ожидаем ChatScreen с сообщениями
      await tester.waitForText('Hello everyone!');
      expect(find.text('Hello everyone!'), findsOneWidget);
      expect(find.text('Hi there!'), findsOneWidget);
    });

    testWidgets('Threads и Drafts rows отображаются', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('Channels');

      expect(find.text('Threads'), findsOneWidget);
      expect(find.text('Drafts'), findsOneWidget);
    });

    testWidgets('поле поиска отображается', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('Channels');

      expect(find.widgetWithText(TextField, 'Search channels...'),
          findsOneWidget);
    });
  });
}
