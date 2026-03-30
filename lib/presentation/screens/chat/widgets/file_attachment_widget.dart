import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
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

class _ImageAttachment extends StatefulWidget {
  final FileInfo fileInfo;
  final List<FileInfo> allMediaFiles;

  const _ImageAttachment({
    required this.fileInfo,
    required this.allMediaFiles,
  });

  @override
  State<_ImageAttachment> createState() => _ImageAttachmentState();
}

class _ImageAttachmentState extends State<_ImageAttachment> {
  Map<String, String>? _headers;

  @override
  void initState() {
    super.initState();
    final token = currentSession.cachedAuthToken;
    if (token != null) {
      _headers = {'Authorization': 'Bearer $token'};
    } else {
      currentSession.getAuthToken().then((t) {
        if (mounted && t != null) {
          setState(() => _headers = {'Authorization': 'Bearer $t'});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_headers == null) return const SizedBox.shrink();

    final thumbnailUrl =
        '${currentSession.baseUrl}${ApiEndpoints.fileThumbnail(widget.fileInfo.id)}';

    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: Hero(
        tag: widget.fileInfo.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 250,
              maxHeight: 200,
            ),
            child: CachedNetworkImage(
              imageUrl: thumbnailUrl,
              httpHeaders: _headers!,
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
  }

  void _openFullscreen(BuildContext context) {
    final mediaFiles = widget.allMediaFiles.isNotEmpty
        ? widget.allMediaFiles
        : [widget.fileInfo];
    final initialIndex = mediaFiles.indexWhere((f) => f.id == widget.fileInfo.id);

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
