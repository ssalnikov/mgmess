import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CategoryHeader extends StatelessWidget {
  final String title;
  final bool collapsed;
  final VoidCallback? onToggle;
  final int? unreadCount;

  const CategoryHeader({
    super.key,
    required this.title,
    this.collapsed = false,
    this.onToggle,
    this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Row(
          children: [
            if (onToggle != null)
              Icon(
                collapsed
                    ? Icons.chevron_right
                    : Icons.expand_more,
                size: 18,
                color: AppColors.textSecondary,
              ),
            if (onToggle != null) const SizedBox(width: 4),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            if (unreadCount != null && unreadCount! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.unreadBadge,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
