import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mgmess/domain/entities/post.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  group('Edit / Delete Messages', () {
    testWidgets('longPress на своё сообщение → Edit → режим редактирования',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks, posts: [
        const Post(
          id: 'own-post',
          channelId: 'ch-001',
          userId: 'user-001', // наш userId
          message: 'My editable message',
          createAt: 1700000003000,
        ),
      ]);
      setupEditMessage(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.waitForText('My editable message');

      // LongPress на своё сообщение
      await tester.longPress(find.text('My editable message'));
      await tester.pumpAndSettle();

      // Видим контекстное меню с Edit
      expect(find.text('Edit'), findsOneWidget);

      // Тапаем Edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Видим индикатор режима редактирования
      expect(find.text('Editing message'), findsOneWidget);
    });

    testWidgets('longPress на своё сообщение → Delete → диалог подтверждения',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks, posts: [
        const Post(
          id: 'own-post-delete',
          channelId: 'ch-001',
          userId: 'user-001',
          message: 'Delete me',
          createAt: 1700000003000,
        ),
      ]);
      setupDeleteMessage(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.waitForText('Delete me');

      // LongPress → Delete
      await tester.longPress(find.text('Delete me'));
      await tester.pumpAndSettle();
      final deleteFinder = find.text('Delete');
      await tester.ensureVisible(deleteFinder.last);
      await tester.pumpAndSettle();
      await tester.tap(deleteFinder.last);
      await tester.pumpAndSettle();

      // Появляется диалог подтверждения
      expect(find.text('Delete message'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this message?'),
          findsOneWidget);

      // Подтверждаем удаление
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      // Verify deletePost вызван
      verify(() => result.mocks.postRepository.deletePost('own-post-delete'))
          .called(1);
    });

    testWidgets(
        'чужое сообщение → нет Edit/Delete, есть Copy/Quote/Forward/Pin',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks, posts: [
        const Post(
          id: 'other-post',
          channelId: 'ch-001',
          userId: 'user-002', // чужой userId
          message: 'Not my message',
          createAt: 1700000003000,
        ),
      ]);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.waitForText('Not my message');

      // LongPress на чужое сообщение
      await tester.longPress(find.text('Not my message'));
      await tester.pumpAndSettle();

      // Есть Copy, Quote, Forward, Pin
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Quote'), findsOneWidget);
      expect(find.text('Forward'), findsOneWidget);
      expect(find.text('Pin'), findsOneWidget);

      // Нет Edit и Delete
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });
  });
}
