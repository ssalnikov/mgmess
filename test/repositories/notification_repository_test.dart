import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/exceptions.dart';
import 'package:mgmess/data/datasources/remote/notification_remote_datasource.dart';
import 'package:mgmess/data/repositories/notification_repository_impl.dart';

class MockNotificationRemoteDataSource extends Mock
    implements NotificationRemoteDataSource {}

void main() {
  late MockNotificationRemoteDataSource mockRemote;
  late NotificationRepositoryImpl repository;

  setUp(() {
    mockRemote = MockNotificationRemoteDataSource();
    repository = NotificationRepositoryImpl(remoteDataSource: mockRemote);
  });

  group('registerDeviceToken', () {
    test('returns Right on success', () async {
      when(() => mockRemote.registerDeviceToken(any()))
          .thenAnswer((_) async {});

      final result = await repository.registerDeviceToken('fcm_token_123');

      expect(result.isRight(), true);
      verify(() => mockRemote.registerDeviceToken('fcm_token_123')).called(1);
    });

    test('returns ServerFailure on ServerException', () async {
      when(() => mockRemote.registerDeviceToken(any()))
          .thenThrow(const ServerException(message: 'Network error'));

      final result = await repository.registerDeviceToken('fcm_token_123');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Network error'),
        (_) => fail('Expected Left'),
      );
    });

    test('returns UnexpectedFailure on unknown exception', () async {
      when(() => mockRemote.registerDeviceToken(any()))
          .thenThrow(Exception('unknown'));

      final result = await repository.registerDeviceToken('fcm_token_123');

      expect(result.isLeft(), true);
    });
  });

  group('unregisterDevice', () {
    test('returns Right on success', () async {
      when(() => mockRemote.unregisterDevice()).thenAnswer((_) async {});

      final result = await repository.unregisterDevice();

      expect(result.isRight(), true);
      verify(() => mockRemote.unregisterDevice()).called(1);
    });

    test('returns ServerFailure on ServerException', () async {
      when(() => mockRemote.unregisterDevice())
          .thenThrow(const ServerException(message: 'Failed'));

      final result = await repository.unregisterDevice();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
