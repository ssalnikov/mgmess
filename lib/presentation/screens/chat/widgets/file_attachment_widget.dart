import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/file_info.dart';
import '../../../widgets/file_icon.dart';
import '../../media/media_viewer_screen.dart';

class FileAttachmentWidget extends StatelessWidget {
  final FileInfo fileInfo;
  final List<FileInfo> allMediaFiles;

  const FileAttachmentWidget({
    super.key,
    required this.fileInfo,
    this.allMediaFiles = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (fileInfo.isImage) {
      return _ImageAttachment(
        fileInfo: fileInfo,
        allMediaFiles: allMediaFiles,
      );
    }
    return _FileAttachment(fileInfo: fileInfo);
  }
}

class _ImageAttachment extends StatelessWidget {
  final FileInfo fileInfo;
  final List<FileInfo> allMediaFiles;

  const _ImageAttachment({
    required this.fileInfo,
    required this.allMediaFiles,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl =
        '${AppConfig.baseUrl}${ApiEndpoints.fileThumbnail(fileInfo.id)}';

    return FutureBuilder<String?>(
      future: sl<SecureStorage>().getToken(),
      builder: (context, snapshot) {
        final token = snapshot.data;
        if (token == null) return const SizedBox.shrink();

        final headers = {'Authorization': 'Bearer $token'};

        return GestureDetector(
          onTap: () => _openFullscreen(context),
          child: Hero(
            tag: fileInfo.id,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 250,
                  maxHeight: 200,
                ),
                child: CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  httpHeaders: headers,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    width: 100,
                    height: 100,
                    color: AppColors.divider,
                    child: const Icon(Icons.image),
                  ),
                  errorWidget: (_, _, _) => Container(
                    width: 100,
                    height: 100,
                    color: AppColors.divider,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openFullscreen(BuildContext context) {
    final mediaFiles = allMediaFiles.isNotEmpty
        ? allMediaFiles
        : [fileInfo];
    final initialIndex = mediaFiles.indexWhere((f) => f.id == fileInfo.id);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaViewerScreen(
          files: mediaFiles,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        ),
      ),
    );
  }
}

class _FileAttachment extends StatelessWidget {
  final FileInfo fileInfo;

  const _FileAttachment({required this.fileInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FileIcon(extension_: fileInfo.extension_),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileInfo.name,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.accent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fileInfo.sizeFormatted,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
