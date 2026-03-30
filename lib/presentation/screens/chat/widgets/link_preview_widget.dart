import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/link_preview.dart';

class LinkPreviewWidget extends StatelessWidget {
  final LinkPreview preview;

  const LinkPreviewWidget({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openUrl(preview.url),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          border: const Border(
            left: BorderSide(color: AppColors.accent, width: 3),
          ),
          color: Colors.black.withValues(alpha: 0.03),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preview.imageUrl != null && preview.imageUrl!.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: preview.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                    placeholder: (_, _) => Container(
                      height: 80,
                      color: AppColors.divider,
                      child: const Center(
                        child: Icon(Icons.image_outlined, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (preview.siteName.isNotEmpty)
                    Text(
                      preview.siteName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (preview.title.isNotEmpty) ...[
                    if (preview.siteName.isNotEmpty)
                      const SizedBox(height: 2),
                    Text(
                      preview.title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (preview.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview.description,
                      style: AppTextStyles.caption,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
