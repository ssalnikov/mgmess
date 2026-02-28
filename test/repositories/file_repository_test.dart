import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/exceptions.dart';
import 'package:mgmess/core/error/failures.dart';
import 'package:mgmess/data/datasources/remote/file_remote_datasource.dart';
import 'package:mgmess/data/models/file_info_model.dart';
import 'package:mgmess/data/repositories/file_repository_impl.dart';

class MockFileRemoteDataSource extends Mock
    implements FileRemoteDataSource {}

void main() {
  late MockFileRemoteDataSource mockRemote;
  late FileRepositoryImpl repository;

  setUp(() {
    mockRemote = MockFileRemoteDataSource();
    repository = FileRepositoryImpl(remoteDataSource: mockRemote);
  });

  const testFileInfo = FileInfoModel(
    id: 'file1',
    postId: 'post1',
    name: 'photo.png',
    extension_: 'png',
    size: 1024,
    mimeType: 'image/png',
    width: 800,
    height: 600,
    hasPreviewImage: true,
  );

  const testFileInfo2 = FileInfoModel(
    id: 'file2',
    postId: 'post1',
    name: 'doc.pdf',
    extension_: 'pdf',
    size: 2048,
    mimeType: 'application/pdf',
  );

  group('FileRepositoryImpl', () {
    group('uploadFiles', () {
      test('returns file infos on success', () async {
        when(() => mockRemote.uploadFiles(
              channelId: any(named: 'channelId'),
              filePaths: any(named: 'filePaths'),
            )).thenAnswer((_) async => [testFileInfo, testFileInfo2]);

        final result = await repository.uploadFiles(
          channelId: 'ch1',
          filePaths: ['/tmp/photo.png', '/tmp/doc.pdf'],
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (files) {
            expect(files, hasLength(2));
            expect(files[0].id, 'file1');
            expect(files[0].name, 'photo.png');
            expect(files[0].isImage, true);
            expect(files[1].id, 'file2');
            expect(files[1].isImage, false);
          },
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.uploadFiles(
              channelId: any(named: 'channelId'),
              filePaths: any(named: 'filePaths'),
            )).thenThrow(const ServerException(message: 'Upload failed'));

        final result = await repository.uploadFiles(
          channelId: 'ch1',
          filePaths: ['/tmp/photo.png'],
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('getFileInfo', () {
      test('returns file info on success', () async {
        when(() => mockRemote.getFileInfo(any()))
            .thenAnswer((_) async => testFileInfo);

        final result = await repository.getFileInfo('file1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (info) {
            expect(info.id, 'file1');
            expect(info.name, 'photo.png');
            expect(info.size, 1024);
          },
        );
      });

      test('returns ServerFailure on ServerException', () async {
        when(() => mockRemote.getFileInfo(any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.getFileInfo('file1');

        expect(result.isLeft(), true);
      });
    });

    group('URL methods', () {
      test('getFileUrl returns URL with file ID', () {
        final url = repository.getFileUrl('file1');
        expect(url, contains('file1'));
        expect(url, contains('files'));
      });

      test('getThumbnailUrl returns URL with file ID', () {
        final url = repository.getThumbnailUrl('file1');
        expect(url, contains('file1'));
        expect(url, contains('thumbnail'));
      });

      test('getPreviewUrl returns URL with file ID', () {
        final url = repository.getPreviewUrl('file1');
        expect(url, contains('file1'));
        expect(url, contains('preview'));
      });
    });
  });
}
