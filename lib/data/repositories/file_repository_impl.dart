import 'package:dartz/dartz.dart';

import '../../core/config/app_config.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/entities/file_info.dart';
import '../../domain/repositories/file_repository.dart';
import '../datasources/remote/file_remote_datasource.dart';

class FileRepositoryImpl implements FileRepository {
  final FileRemoteDataSource _remoteDataSource;

  FileRepositoryImpl({required FileRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

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
  String getFileUrl(String fileId) =>
      '${AppConfig.baseUrl}${ApiEndpoints.file(fileId)}';

  @override
  String getThumbnailUrl(String fileId) =>
      '${AppConfig.baseUrl}${ApiEndpoints.fileThumbnail(fileId)}';

  @override
  String getPreviewUrl(String fileId) =>
      '${AppConfig.baseUrl}${ApiEndpoints.filePreview(fileId)}';
}
