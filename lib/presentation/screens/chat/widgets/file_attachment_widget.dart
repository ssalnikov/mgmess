import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/file_info.dart';
import '../../../widgets/file_icon.dart';

class FileAttachmentWidget extends StatelessWidget {
  final FileInfo fileInfo;

  const FileAttachmentWidget({super.key, required this.fileInfo});

  @override
  Widget build(BuildContext context) {
    if (fileInfo.isImage) {
      return _ImageAttachment(fileInfo: fileInfo);
    }
    return _FileAttachment(fileInfo: fileInfo);
  }
}

class _ImageAttachment extends StatelessWidget {
  final FileInfo fileInfo;

  const _ImageAttachment({required this.fileInfo});

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl =
        '${AppConfig.baseUrl}${ApiEndpoints.fileThumbnail(fileInfo.id)}';
    final fullUrl =
        '${AppConfig.baseUrl}${ApiEndpoints.file(fileInfo.id)}';

    return FutureBuilder<String?>(
      future: sl<SecureStorage>().getToken(),
      builder: (context, snapshot) {
        final token = snapshot.data;
        if (token == null) return const SizedBox.shrink();

        final headers = {'Authorization': 'Bearer $token'};

        return GestureDetector(
          onTap: () => _openFullscreen(context, fullUrl, headers),
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
                placeholder: (_, __) => Container(
                  width: 100,
                  height: 100,
                  color: AppColors.divider,
                  child: const Icon(Icons.image),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: AppColors.divider,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openFullscreen(
    BuildContext context,
    String url,
    Map<String, String> headers,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              fileInfo.name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(
              url,
              headers: headers,
            ),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
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
