import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../models/file_info_model.dart';

class FileRemoteDataSource {
  final ApiClient _apiClient;

  FileRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<FileInfoModel>> uploadFiles({
    required String channelId,
    required List<String> filePaths,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('channel_id', channelId));

      for (final path in filePaths) {
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(path),
        ));
      }

      final response = await _apiClient.dio.post(
        ApiEndpoints.files,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final fileInfos = data['file_infos'] as List<dynamic>? ?? [];
      return fileInfos
          .map((f) =>
              FileInfoModel.fromJson(f as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to upload files: $e');
    }
  }

  Future<FileInfoModel> getFileInfo(String fileId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.file(fileId)}/info',
      );
      return FileInfoModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to get file info: $e');
    }
  }
}
