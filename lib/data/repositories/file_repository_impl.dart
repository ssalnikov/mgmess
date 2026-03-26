import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/entities/file_info.dart';
import '../../domain/repositories/file_repository.dart';
import '../datasources/remote/file_remote_datasource.dart';

class FileRepositoryImpl implements FileRepository {
  final FileRemoteDataSource _remoteDataSource;
  final String _baseUrl;

  FileRepositoryImpl({
    required FileRemoteDataSource remoteDataSource,
    required String baseUrl,
  })  : _remoteDataSource = remoteDataSource,
        _baseUrl = baseUrl;

  @override
  Future<Either<Failure, List<FileInfo>>> uploadFiles({
    required String channelId,
    required List<String> filePaths,
  }) async {
    try {
      final files = await _remoteDataSource.uploadFiles(
        channelId: channelId,
        filePaths: filePaths,
      );
      return Right(files);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, FileInfo>> getFileInfo(String fileId) async {
    try {
      final info = await _remoteDataSource.getFileInfo(fileId);
      return Right(info);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<({FileInfo file, int createAt})>>> getChannelFiles(
    String channelId, {
    int page = 0,
    int perPage = 20,
  }) async {
    try {
      final files = await _remoteDataSource.getChannelFiles(
        channelId,
        page: page,
        perPage: perPage,
      );
      return Right(files.map((f) => (file: f.file as FileInfo, createAt: f.createAt)).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  String getFileUrl(String fileId) =>
      '$_baseUrl${ApiEndpoints.file(fileId)}';

  @override
  String getThumbnailUrl(String fileId) =>
      '$_baseUrl${ApiEndpoints.fileThumbnail(fileId)}';

  @override
  String getPreviewUrl(String fileId) =>
      '$_baseUrl${ApiEndpoints.filePreview(fileId)}';
}
