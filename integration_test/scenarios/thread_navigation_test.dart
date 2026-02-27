import 'package:flutter_test/flutter_test.dart';

import 'package:mgmess/domain/entities/post.dart';

import '../fixtures/test_data.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  group('Thread Navigation', () {
    testWidgets('тап по reply count → ThreadScreen открывается',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks, posts: [testPostWithReply]);
      setupThread(result.mocks, posts: [
        testPostWithReply,
        const Post(
          id: 'reply-001',
          channelId: 'ch-001',
          userId: 'user-001',
          rootId: 'post-with-reply',
          message: 'Reply to the post',
          createAt: 1700000006000,
        ),
      ]);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.waitForText('General');
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.waitForText('Post with replies');

      // Видим reply count
      expect(find.text('2 replies'), findsOneWidget);

      // Тапаем по сообщению (tap opens thread via onThreadTap)
      await tester.tap(find.text('Post with replies'));
      await tester.pumpAndSettle();

      // ThreadScreen должен открыться с содержимым треда
      await tester.waitForText('Reply to the post');
      expect(find.text('Reply to the post'), findsOneWidget);
    });
  });
}
