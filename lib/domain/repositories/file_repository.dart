import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/file_info.dart';

abstract class FileRepository {
  Future<Either<Failure, List<FileInfo>>> uploadFiles({
    required String channelId,
    required List<String> filePaths,
  });
  Future<Either<Failure, FileInfo>> getFileInfo(String fileId);
  Future<Either<Failure, List<({FileInfo file, int createAt})>>> getChannelFiles(
    String channelId, {
    int page,
    int perPage,
  });
  String getFileUrl(String fileId);
  String getThumbnailUrl(String fileId);
  String getPreviewUrl(String fileId);
}
