import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  group('Send Message', () {
    testWidgets('отправка сообщения → createPost вызван', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks);
      setupSendMessage(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      // Переходим в канал General
      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();

      // Ждём загрузки сообщений
      await tester.waitForText('Hello everyone!');

      // Вводим текст в поле сообщения
      final messageField =
          find.widgetWithText(TextField, 'Write a message...');
      expect(messageField, findsOneWidget);

      await tester.enterText(messageField, 'My new message');
      await tester.pump();

      // Нажимаем кнопку отправки
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify createPost был вызван
      verify(() => result.mocks.postRepository.createPost(
            channelId: 'ch-001',
            message: 'My new message',
            rootId: any(named: 'rootId'),
            fileIds: any(named: 'fileIds'),
            priority: any(named: 'priority'),
          )).called(1);
    });

    testWidgets('поле ввода очищается после отправки', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks);
      setupSendMessage(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.waitForText('Hello everyone!');

      final messageField =
          find.widgetWithText(TextField, 'Write a message...');
      await tester.enterText(messageField, 'Test message');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Поле ввода должно быть очищено
      final textField = tester.widget<TextField>(
        find.byType(TextField).last,
      );
      expect(textField.controller?.text, isEmpty);
    });
  });
}
