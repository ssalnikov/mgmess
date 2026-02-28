import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/exceptions.dart';
import 'package:mgmess/core/error/failures.dart';
import 'package:mgmess/data/datasources/remote/seens_remote_datasource.dart';
import 'package:mgmess/data/models/seen_list_model.dart';
import 'package:mgmess/data/repositories/seens_repository_impl.dart';

class MockSeensRemoteDataSource extends Mock
    implements SeensRemoteDataSource {}

void main() {
  late MockSeensRemoteDataSource mockRemote;
  late SeensRepositoryImpl repository;

  setUp(() {
    mockRemote = MockSeensRemoteDataSource();
    repository = SeensRepositoryImpl(remoteDataSource: mockRemote);
  });

  const testSeenList = SeenListModel(
    channelId: 'ch1',
    users: [
      UserSeenModel(
        odataId: 'user1',
        firstName: 'Test',
        lastName: 'User',
        userName: 'testuser',
        seenAt: 1700000000000,
      ),
    ],
  );

  const testPostSeenList = SeenListModel(
    postId: 'post1',
    users: [
      UserSeenModel(
        odataId: 'user1',
        firstName: 'Test',
        lastName: 'User',
        userName: 'testuser',
        seenAt: 1700000000000,
      ),
      UserSeenModel(
        odataId: 'user2',
        firstName: 'Another',
        userName: 'another',
        seenAt: 1700000001000,
      ),
    ],
  );

  group('SeensRepositoryImpl', () {
    group('getChannelSeens', () {
      test('returns SeenList on success', () async {
        when(() => mockRemote.getChannelSeens(any()))
            .thenAnswer((_) async => testSeenList);

        final result = await repository.getChannelSeens('ch1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (seenList) {
            expect(seenList.channelId, 'ch1');
            expect(seenList.users, hasLength(1));
            expect(seenList.users[0].userName, 'testuser');
            expect(seenList.users[0].seenAt, 1700000000000);
          },
        );
        verify(() => mockRemote.getChannelSeens('ch1')).called(1);
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.getChannelSeens(any()))
            .thenThrow(
                const ServerException(message: 'Failed to get seens'));

        final result = await repository.getChannelSeens('ch1');

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, 'Failed to get seens');
          },
          (_) => fail('Expected Left'),
        );
      });
    });

    group('getPostSeens', () {
      test('returns SeenList on success', () async {
        when(() => mockRemote.getPostSeens(any()))
            .thenAnswer((_) async => testPostSeenList);

        final result = await repository.getPostSeens('post1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (seenList) {
            expect(seenList.postId, 'post1');
            expect(seenList.users, hasLength(2));
          },
        );
        verify(() => mockRemote.getPostSeens('post1')).called(1);
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.getPostSeens(any()))
            .thenThrow(
                const ServerException(message: 'Failed to get seens'));

        final result = await repository.getPostSeens('post1');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });
  });
}
