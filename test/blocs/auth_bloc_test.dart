import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/failures.dart';
import 'package:mgmess/domain/entities/team.dart';
import 'package:mgmess/domain/entities/user.dart';
import 'package:mgmess/domain/repositories/auth_repository.dart';
import 'package:mgmess/presentation/blocs/auth/auth_bloc.dart';
import 'package:mgmess/presentation/blocs/auth/auth_event.dart';
import 'package:mgmess/presentation/blocs/auth/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  const testUser = User(
    id: 'user1',
    username: 'testuser',
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
  );

  const testTeam = Team(id: 'team1', name: 'test-team');

  group('AuthBloc', () {
    group('AuthCheckSession', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when session is valid',
        build: () {
          when(() => mockAuthRepository.hasValidSession())
              .thenAnswer((_) async => true);
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => const Right(testUser));
          when(() => mockAuthRepository.getMyTeams())
              .thenAnswer((_) async => const Right([testTeam]));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthCheckSession()),
        expect: () => [
          const AuthLoading(),
          const AuthAuthenticated(user: testUser, teamId: 'team1'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when no session',
        build: () {
          when(() => mockAuthRepository.hasValidSession())
              .thenAnswer((_) async => false);
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthCheckSession()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when getCurrentUser fails',
        build: () {
          when(() => mockAuthRepository.hasValidSession())
              .thenAnswer((_) async => true);
          when(() => mockAuthRepository.getCurrentUser()).thenAnswer(
            (_) async =>
                const Left(ServerFailure(message: 'Server error')),
          );
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthCheckSession()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(message: 'Server error'),
        ],
      );
    });

    group('AuthOAuthCompleted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] on successful OAuth',
        build: () {
          when(() => mockAuthRepository.saveAuthTokens(
                token: any(named: 'token'),
                csrfToken: any(named: 'csrfToken'),
              )).thenAnswer((_) async => const Right(null));
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => const Right(testUser));
          when(() => mockAuthRepository.getMyTeams())
              .thenAnswer((_) async => const Right([testTeam]));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthOAuthCompleted(
          token: 'token123',
          csrfToken: 'csrf456',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthAuthenticated(user: testUser, teamId: 'team1'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when save tokens fails',
        build: () {
          when(() => mockAuthRepository.saveAuthTokens(
                token: any(named: 'token'),
                csrfToken: any(named: 'csrfToken'),
              )).thenAnswer(
            (_) async =>
                const Left(CacheFailure(message: 'Storage error')),
          );
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthOAuthCompleted(
          token: 'token123',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Failed to save auth tokens'),
        ],
      );
    });

    group('AuthLoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] on successful login',
        build: () {
          when(() => mockAuthRepository.login(
                loginId: any(named: 'loginId'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => const Right(testUser));
          when(() => mockAuthRepository.getMyTeams())
              .thenAnswer((_) async => const Right([testTeam]));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          loginId: 'testuser',
          password: 'password123',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthAuthenticated(user: testUser, teamId: 'team1'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails',
        build: () {
          when(() => mockAuthRepository.login(
                loginId: any(named: 'loginId'),
                password: any(named: 'password'),
              )).thenAnswer(
            (_) async =>
                const Left(ServerFailure(message: 'Invalid credentials')),
          );
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          loginId: 'testuser',
          password: 'wrongpassword',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError(message: 'Invalid credentials'),
        ],
      );
    });

    group('AuthLoadConfig', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthConfigLoaded] with config values on success',
        build: () {
          when(() => mockAuthRepository.getClientConfig()).thenAnswer(
            (_) async => const Right({
              'EnableSignInWithEmail': 'true',
              'EnableSignInWithUsername': 'true',
              'EnableSignUpWithGitlab': 'true',
            }),
          );
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthLoadConfig()),
        expect: () => [
          const AuthConfigLoaded(
            enableSignInWithEmail: true,
            enableSignInWithUsername: true,
            enableSignUpWithGitLab: true,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthConfigLoaded] with false values when disabled',
        build: () {
          when(() => mockAuthRepository.getClientConfig()).thenAnswer(
            (_) async => const Right({
              'EnableSignInWithEmail': 'false',
              'EnableSignInWithUsername': 'false',
              'EnableSignUpWithGitlab': 'true',
            }),
          );
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthLoadConfig()),
        expect: () => [
          const AuthConfigLoaded(
            enableSignInWithEmail: false,
            enableSignInWithUsername: false,
            enableSignUpWithGitLab: true,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthConfigLoaded] with defaults on failure',
        build: () {
          when(() => mockAuthRepository.getClientConfig()).thenAnswer(
            (_) async =>
                const Left(ServerFailure(message: 'Network error')),
          );
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthLoadConfig()),
        expect: () => [
          const AuthConfigLoaded(
            enableSignInWithEmail: false,
            enableSignInWithUsername: false,
            enableSignUpWithGitLab: true,
          ),
        ],
      );
    });

    group('AuthLogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthUnauthenticated] on logout',
        build: () {
          when(() => mockAuthRepository.logout())
              .thenAnswer((_) async => const Right(null));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthUnauthenticated(),
        ],
      );
    });
  });
}
