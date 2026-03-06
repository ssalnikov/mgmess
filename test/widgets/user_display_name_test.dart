import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/domain/entities/user.dart';
import 'package:mgmess/domain/repositories/user_repository.dart';
import 'package:mgmess/presentation/blocs/user_status/user_status_cubit.dart';
import 'package:mgmess/presentation/widgets/user_display_name.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockRepo;
  late UserStatusCubit cubit;

  setUp(() {
    mockRepo = MockUserRepository();
    cubit = UserStatusCubit(userRepository: mockRepo);
  });

  tearDown(() => cubit.close());

  Widget buildWidget({
    required String userId,
    required String displayName,
    TextStyle? style,
    String? fallbackEmoji,
  }) {
    return MaterialApp(
      home: BlocProvider<UserStatusCubit>.value(
        value: cubit,
        child: Scaffold(
          body: UserDisplayName(
            userId: userId,
            displayName: displayName,
            style: style,
            fallbackEmoji: fallbackEmoji,
          ),
        ),
      ),
    );
  }

  group('UserDisplayName', () {
    testWidgets('shows only name when no custom status', (tester) async {
      await tester.pumpWidget(buildWidget(
        userId: 'user1',
        displayName: 'John Doe',
      ));

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('shows emoji from cubit custom status', (tester) async {
      cubit.setCustomStatusFromUser(const _FakeUser(
        id: 'user1',
        emoji: 'palm_tree',
        text: 'On vacation',
      ));

      await tester.pumpWidget(buildWidget(
        userId: 'user1',
        displayName: 'John Doe',
      ));

      expect(find.text('John Doe'), findsOneWidget);
      // palm_tree emoji should be rendered
      expect(find.byType(Row), findsOneWidget);
      // There should be 2 Text widgets: name + emoji
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      expect(texts.length, 2);
      expect(texts[0], 'John Doe');
      expect(texts[1], isNotEmpty); // emoji char
    });

    testWidgets('uses fallbackEmoji when cubit has no data', (tester) async {
      await tester.pumpWidget(buildWidget(
        userId: 'user1',
        displayName: 'John Doe',
        fallbackEmoji: 'coffee',
      ));

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      expect(texts.length, 2);
      expect(texts[0], 'John Doe');
      expect(texts[1], isNotEmpty); // coffee emoji
    });

    testWidgets('cubit overrides fallbackEmoji', (tester) async {
      cubit.setCustomStatusFromUser(const _FakeUser(
        id: 'user1',
        emoji: 'rocket',
        text: 'Launching',
      ));

      await tester.pumpWidget(buildWidget(
        userId: 'user1',
        displayName: 'John Doe',
        fallbackEmoji: 'coffee',
      ));

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      expect(texts.length, 2);
      expect(texts[0], 'John Doe');
      // Should show rocket (from cubit), not coffee (fallback)
      expect(texts[1], contains('\u{1F680}')); // rocket unicode
    });

    testWidgets('shows only name when fallbackEmoji is empty', (tester) async {
      await tester.pumpWidget(buildWidget(
        userId: 'user1',
        displayName: 'John Doe',
        fallbackEmoji: '',
      ));

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('updates when cubit state changes', (tester) async {
      await tester.pumpWidget(buildWidget(
        userId: 'user1',
        displayName: 'John Doe',
      ));

      // Initially just text
      expect(find.byType(Row), findsNothing);

      // Set custom status
      cubit.setCustomStatusFromUser(const _FakeUser(
        id: 'user1',
        emoji: 'fire',
        text: 'Hot',
      ));

      await tester.pump();

      // Now should show emoji
      expect(find.byType(Row), findsOneWidget);
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      expect(texts.length, 2);
    });

    testWidgets('handles unknown emoji shortcode gracefully', (tester) async {
      cubit.setCustomStatusFromUser(const _FakeUser(
        id: 'user1',
        emoji: 'some_unknown_emoji_xyz',
        text: 'Test',
      ));

      await tester.pumpWidget(buildWidget(
        userId: 'user1',
        displayName: 'John Doe',
      ));

      // Should still render without error
      expect(find.text('John Doe'), findsOneWidget);
      // Unknown emoji renders as the shortcode itself
      expect(find.text('some_unknown_emoji_xyz'), findsOneWidget);
    });
  });
}

/// Minimal User for testing that carries custom status fields.
class _FakeUser extends User {
  const _FakeUser({
    required String id,
    String emoji = '',
    String text = '',
  }) : super(
          id: id,
          username: 'test',
          customStatusEmoji: emoji,
          customStatusText: text,
        );
}
