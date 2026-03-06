import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mgmess/core/utils/emoji_map.dart';
import 'package:mgmess/domain/entities/user.dart';
import 'package:mgmess/presentation/widgets/user_display_name.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  group('Custom Status — channel list', () {
    testWidgets('DM канал показывает эмодзи custom status рядом с именем',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);

      // DM user has custom status
      when(() => result.mocks.userRepository.getUser('user-002'))
          .thenAnswer((_) async => const Right(User(
                id: 'user-002',
                username: 'otheruser',
                firstName: 'Other',
                lastName: 'User',
                customStatusEmoji: 'palm_tree',
                customStatusText: 'On vacation',
              )));

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();
      await tester.waitForText('Other User');

      // UserDisplayName should be used for the DM tile
      expect(find.byType(UserDisplayName), findsWidgets);

      // The palm_tree emoji should be visible
      final palmEmoji = emojiMap['palm_tree']!;
      expect(find.text(palmEmoji), findsOneWidget);
    });

    testWidgets('DM канал без custom status не показывает эмодзи',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);

      // DM user without custom status (default mock)
      when(() => result.mocks.userRepository.getUser('user-002'))
          .thenAnswer((_) async => const Right(User(
                id: 'user-002',
                username: 'otheruser',
                firstName: 'Other',
                lastName: 'User',
              )));

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();
      await tester.waitForText('Other User');

      // palm_tree emoji should NOT be visible
      final palmEmoji = emojiMap['palm_tree']!;
      expect(find.text(palmEmoji), findsNothing);
    });
  });

  group('Custom Status — chat screen', () {
    testWidgets('AppBar DM чата показывает эмодзи custom status',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);
      setupChannelPosts(result.mocks);

      // DM user has custom status
      when(() => result.mocks.userRepository.getUser('user-002'))
          .thenAnswer((_) async => const Right(User(
                id: 'user-002',
                username: 'otheruser',
                firstName: 'Other',
                lastName: 'User',
                customStatusEmoji: 'coffee',
                customStatusText: 'Having lunch',
              )));
      when(() => result.mocks.userRepository.getUsersByIds(['user-002']))
          .thenAnswer((_) async => const Right([
                User(
                  id: 'user-002',
                  username: 'otheruser',
                  firstName: 'Other',
                  lastName: 'User',
                  customStatusEmoji: 'coffee',
                  customStatusText: 'Having lunch',
                ),
              ]));

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();
      await tester.waitForText('Other User');

      // Tap DM channel
      await tester.tap(find.text('Other User').last);
      await tester.pumpAndSettle();

      // Wait for chat to load
      await tester.waitForText('Hello everyone!');

      // Chat AppBar should contain UserDisplayName
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);

      // Coffee emoji should be shown in the AppBar
      final coffeeEmoji = emojiMap['coffee']!;
      expect(find.text(coffeeEmoji), findsOneWidget);
    });
  });
}
