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

  /// Loads channel posts in batches and returns files from posts that have attachments.
  /// Returns tuples of (FileInfoModel, createAt timestamp for sorting).
  Future<List<({FileInfoModel file, int createAt})>> getChannelFiles(
    String channelId, {
    int page = 0,
    int perPage = 20,
  }) async {
    try {
      final files = <({FileInfoModel file, int createAt})>[];
      String? beforePostId;
      final skip = page * perPage;
      var skipped = 0;

      // Scan through channel posts to find ones with files
      for (var i = 0; i < 10; i++) {
        // Max 10 batches to avoid infinite loop
        final queryParams = <String, dynamic>{'per_page': 200};
        if (beforePostId != null) queryParams['before'] = beforePostId;

        final response = await _apiClient.dio.get(
          ApiEndpoints.channelPosts(channelId),
          queryParameters: queryParams,
        );
        final data = response.data as Map<String, dynamic>;
        final posts = data['posts'] as Map<String, dynamic>? ?? {};
        final order = (data['order'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [];

        if (order.isEmpty) break;

        for (final postId in order) {
          final postJson = posts[postId] as Map<String, dynamic>?;
          if (postJson == null) continue;

          final fileIds =
              (postJson['file_ids'] as List<dynamic>?)?.cast<String>() ?? [];
          if (fileIds.isEmpty) continue;

          final createAt = postJson['create_at'] as int? ?? 0;

          // Parse files from metadata if available
          final metadata = postJson['metadata'] as Map<String, dynamic>?;
          final metadataFiles = metadata?['files'] as List<dynamic>?;

          if (metadataFiles != null) {
            for (final f in metadataFiles) {
              if (skipped < skip) {
                skipped++;
                continue;
              }
              files.add((
                file: FileInfoModel.fromJson(f as Map<String, dynamic>),
                createAt: createAt,
              ));
              if (files.length >= perPage) return files;
            }
          } else {
            // Fallback: create minimal FileInfoModel from file_ids
            for (final fid in fileIds) {
              if (skipped < skip) {
                skipped++;
                continue;
              }
              try {
                final fileInfo = await getFileInfo(fid);
                files.add((file: fileInfo, createAt: createAt));
                if (files.length >= perPage) return files;
              } catch (_) {}
            }
          }
        }

        beforePostId = order.last;
        if (order.length < 200) break; // No more posts
      }

      return files;
    } catch (e) {
      throw ServerException(message: 'Failed to get channel files: $e');
    }
  }
}
