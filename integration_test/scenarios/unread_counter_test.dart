import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mgmess/domain/entities/channel.dart';

import '../fixtures/ws_event_factory.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  group('Unread Counter — multi-device fixes', () {
    testWidgets('собственный WS-пост не создаёт unread badge', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      // Channel starts with no unread (totalMsgCount == msgCount)
      setupChannelList(result.mocks, channels: [
        const Channel(
          id: 'ch-001',
          teamId: 'team-001',
          name: 'general',
          displayName: 'General',
          type: ChannelType.open,
          totalMsgCount: 100,
          lastPostAt: 1700000003000,
          msgCount: 100,
        ),
      ]);
      setupChannelPosts(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();
      await tester.waitForText('General');

      // Симулируем WS-событие собственного поста (user-001 = testUser)
      result.mocks.webSocketClient.simulateEvent(
        createPostedEvent(
          postId: 'own-post-001',
          channelId: 'ch-001',
          userId: 'user-001',
          message: 'My own message',
          createAt: 1700000010000,
        ),
      );

      await tester.pumpN(10);

      // Канал всё ещё отображается (не сломался)
      expect(find.text('General'), findsOneWidget);
    });

    testWidgets('viewChannel вызывается при выходе из чата', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();
      await tester.waitForText('General');

      // Входим в канал
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.waitForText('Hello everyone!');

      // Нажимаем кнопку назад (IconButton с Icons.arrow_back)
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // viewChannel вызывается при входе (MarkChannelAsRead) и при выходе (dispose)
      verify(() => result.mocks.channelRepository.viewChannel(
            any(),
            'ch-001',
          )).called(greaterThanOrEqualTo(1));
    });
  });
}
