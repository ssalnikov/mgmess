import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/storage/secure_storage.dart';
import 'package:mgmess/data/datasources/remote/auth_remote_datasource.dart';
import 'package:mgmess/data/models/user_model.dart';
import 'package:mgmess/data/repositories/auth_repository_impl.dart';
import 'package:mgmess/core/error/exceptions.dart';

class MockAuthRemoteDataSource extends Mock
    implements AuthRemoteDataSource {}

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late MockAuthRemoteDataSource mockRemote;
  late MockSecureStorage mockStorage;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockStorage = MockSecureStorage();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemote,
      secureStorage: mockStorage,
    );
  });

  const testUser = UserModel(
    id: 'user1',
    username: 'testuser',
    email: 'test@example.com',
  );

  group('getCurrentUser', () {
    test('returns user on success', () async {
      when(() => mockRemote.getCurrentUser())
          .thenAnswer((_) async => testUser);
      when(() => mockStorage.saveUserId(any()))
          .thenAnswer((_) async {});

      final result = await repository.getCurrentUser();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (user) {
          expect(user.id, 'user1');
          expect(user.username, 'testuser');
        },
      );
      verify(() => mockStorage.saveUserId('user1')).called(1);
    });

    test('returns ServerFailure on exception', () async {
      when(() => mockRemote.getCurrentUser())
          .thenThrow(const ServerException(message: 'Error'));

      final result = await repository.getCurrentUser();
      expect(result.isLeft(), true);
    });
  });

  group('saveAuthTokens', () {
    test('saves token and csrf', () async {
      when(() => mockStorage.saveToken(any()))
          .thenAnswer((_) async {});
      when(() => mockStorage.saveCsrfToken(any()))
          .thenAnswer((_) async {});

      final result = await repository.saveAuthTokens(
        token: 'tok',
        csrfToken: 'csrf',
      );

      expect(result.isRight(), true);
      verify(() => mockStorage.saveToken('tok')).called(1);
      verify(() => mockStorage.saveCsrfToken('csrf')).called(1);
    });
  });

  group('logout', () {
    test('clears storage even on server error', () async {
      when(() => mockRemote.logout())
          .thenThrow(const ServerException(message: 'error'));
      when(() => mockStorage.clearAll()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result.isRight(), true);
      verify(() => mockStorage.clearAll()).called(1);
    });
  });

  group('hasValidSession', () {
    test('returns true when token exists and user loads', () async {
      when(() => mockStorage.getToken())
          .thenAnswer((_) async => 'token');
      when(() => mockRemote.getCurrentUser())
          .thenAnswer((_) async => testUser);

      final result = await repository.hasValidSession();
      expect(result, true);
    });

    test('returns false when no token', () async {
      when(() => mockStorage.getToken())
          .thenAnswer((_) async => null);

      final result = await repository.hasValidSession();
      expect(result, false);
    });

    test('returns false when getCurrentUser throws', () async {
      when(() => mockStorage.getToken())
          .thenAnswer((_) async => 'token');
      when(() => mockRemote.getCurrentUser())
          .thenThrow(const ServerException(message: 'error'));

      final result = await repository.hasValidSession();
      expect(result, false);
    });
  });
}
