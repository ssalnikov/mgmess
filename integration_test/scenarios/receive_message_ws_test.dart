import 'package:flutter_test/flutter_test.dart';

import 'package:mgmess/domain/entities/post.dart';

import '../fixtures/ws_event_factory.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  group('Receive Message via WebSocket', () {
    testWidgets('получение через WS → новое сообщение в чате',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      // Переходим в канал General
      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();

      // Ждём загрузки существующих сообщений
      await tester.waitForText('Hello everyone!');

      // Симулируем WS-событие нового поста
      result.mocks.webSocketClient.simulateEvent(
        createPostedEvent(
          postId: 'ws-post-001',
          channelId: 'ch-001',
          userId: 'user-002',
          message: 'Message from WebSocket!',
        ),
      );

      // Ждём появления нового сообщения
      await tester.waitForText('Message from WebSocket!');
      expect(find.text('Message from WebSocket!'), findsOneWidget);
    });

    testWidgets('сообщение из другого канала не появляется в текущем чате',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.waitForText('Hello everyone!');

      // Симулируем WS-событие поста из ДРУГОГО канала
      result.mocks.webSocketClient.simulateEvent(
        createPostedEvent(
          postId: 'ws-post-other',
          channelId: 'ch-002', // Flutter Development, не General
          userId: 'user-002',
          message: 'Wrong channel message',
        ),
      );

      await tester.pumpN(10);

      // Сообщение из другого канала не должно появиться
      expect(find.text('Wrong channel message'), findsNothing);
    });

    testWidgets('typing indicator появляется при WS typing event',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.waitForText('Hello everyone!');

      // Симулируем typing event
      result.mocks.webSocketClient.simulateEvent(
        createTypingEvent(
          channelId: 'ch-001',
          userId: 'user-002',
        ),
      );

      await tester.pumpN(5);

      // Typing indicator виден
      expect(find.textContaining('typing...'), findsOneWidget);
    });

    testWidgets('WS post_edited обновляет сообщение', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks, posts: [
        const Post(
          id: 'post-edit-target',
          channelId: 'ch-001',
          userId: 'user-002',
          message: 'Original message',
          createAt: 1700000003000,
        ),
      ]);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.waitForText('Original message');

      // Симулируем WS-событие редактирования
      result.mocks.webSocketClient.simulateEvent(
        createPostEditedEvent(
          postId: 'post-edit-target',
          channelId: 'ch-001',
          userId: 'user-002',
          newMessage: 'Edited message',
        ),
      );

      await tester.waitForText('Edited message');
      expect(find.text('Edited message'), findsOneWidget);
      expect(find.text('Original message'), findsNothing);
    });
  });
}
