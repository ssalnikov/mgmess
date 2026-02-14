import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/file_info.dart';

abstract class FileRepository {
  Future<Either<Failure, List<FileInfo>>> uploadFiles({
    required String channelId,
    required List<String> filePaths,
  });
  Future<Either<Failure, FileInfo>> getFileInfo(String fileId);
  String getFileUrl(String fileId);
  String getThumbnailUrl(String fileId);
  String getPreviewUrl(String fileId);
}
