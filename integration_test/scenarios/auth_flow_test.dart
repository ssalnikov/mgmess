import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mgmess/core/error/failures.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  group('Auth Flow', () {
    testWidgets('показывает AuthScreen для неавторизованного пользователя',
        (tester) async {
      final result = await createTestApp();
      setupUnauthenticatedState(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      // Видим заголовок MGMess
      expect(find.text('MGMess'), findsOneWidget);
      // Видим кнопку GitLab OAuth
      expect(find.text('Sign in with GitLab'), findsOneWidget);
    });

    testWidgets('показывает форму логина при включенном email+username',
        (tester) async {
      final result = await createTestApp();
      setupUnauthenticatedState(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      // AuthLoadConfig загружает конфиг, показывается форма
      expect(find.text('Email or Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('login по паролю → навигация на каналы', (tester) async {
      final result = await createTestApp();
      setupUnauthenticatedState(result.mocks);
      setupLogin(result.mocks);
      setupChannelList(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      // Вводим логин и пароль
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email or Username'),
          'test@my.games');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');

      // Нажимаем Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Ожидаем навигацию на экран каналов
      // "Channels" есть и в AppBar, и в BottomNavigationBar
      await tester.waitForText('Channels');
      expect(find.text('Channels'), findsAtLeastNWidgets(1));

      // Verify login was called
      verify(() => result.mocks.authRepository.login(
            loginId: 'test@my.games',
            password: 'password123',
          )).called(1);
    });

    testWidgets('восстановление сессии → сразу каналы', (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);
      setupChannelList(result.mocks);

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      // Сразу видим экран каналов без логина
      // "Channels" есть и в AppBar, и в BottomNavigationBar
      await tester.waitForText('Channels');
      expect(find.text('Channels'), findsAtLeastNWidgets(1));

      // Login не вызывался
      verifyNever(() => result.mocks.authRepository.login(
            loginId: any(named: 'loginId'),
            password: any(named: 'password'),
          ));
    });

    testWidgets('ошибка авторизации показывает SnackBar', (tester) async {
      final result = await createTestApp();
      setupUnauthenticatedState(result.mocks);

      // login вернёт ошибку
      when(() => result.mocks.authRepository.login(
            loginId: any(named: 'loginId'),
            password: any(named: 'password'),
          )).thenAnswer((_) async =>
              const Left(AuthFailure(message: 'Invalid credentials')));

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email or Username'), 'wrong');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'wrong');
      await tester.tap(find.text('Sign In'));

      await tester.pumpN(20);

      // SnackBar с ошибкой
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });
}
