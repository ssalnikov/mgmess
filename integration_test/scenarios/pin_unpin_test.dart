import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mgmess/domain/entities/post.dart';

import '../fixtures/test_data.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  group('Pin / Unpin Messages', () {
    testWidgets('longPress → контекстное меню → Pin → verify pinPost',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks, posts: [
        const Post(
          id: 'post-to-pin',
          channelId: 'ch-001',
          userId: 'user-002',
          message: 'Pin this message',
          createAt: 1700000003000,
          isPinned: false,
        ),
      ]);
      setupPinMessage(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.waitForText('Pin this message');

      // LongPress на сообщение
      await tester.longPress(find.text('Pin this message'));
      await tester.pumpAndSettle();

      // Видим контекстное меню с Pin
      expect(find.text('Pin'), findsOneWidget);

      // Тапаем Pin
      await tester.tap(find.text('Pin'));
      await tester.pumpAndSettle();

      // Verify pinPost вызван
      verify(() => result.mocks.postRepository.pinPost('post-to-pin'))
          .called(1);
    });

    testWidgets('longPress на pinned → Unpin → verify unpinPost',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks, posts: [testPinnedPost]);
      setupPinMessage(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.waitForText('This is pinned');

      // LongPress на pinned сообщение
      await tester.longPress(find.text('This is pinned'));
      await tester.pumpAndSettle();

      // Видим Unpin вместо Pin
      expect(find.text('Unpin'), findsOneWidget);
      expect(find.text('Pin'), findsNothing);

      // Тапаем Unpin
      await tester.tap(find.text('Unpin'));
      await tester.pumpAndSettle();

      verify(() => result.mocks.postRepository.unpinPost('post-pinned'))
          .called(1);
    });

    testWidgets('pinned сообщение показывает индикатор Pinned',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks, posts: [testPinnedPost]);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.waitForText('This is pinned');

      // Видим индикатор Pinned
      expect(find.text('Pinned'), findsOneWidget);
    });
  });
}
