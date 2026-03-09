import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/user.dart';
import '../../../widgets/user_avatar.dart';
import '../../../widgets/user_display_name.dart';

/// Represents either a regular user mention or a special mention (@all, @channel, @here).
class MentionItem {
  final User? user;
  final String? specialMention;
  final String? specialDescription;

  const MentionItem.user(this.user)
      : specialMention = null,
        specialDescription = null;

  const MentionItem.special({
    required this.specialMention,
    required this.specialDescription,
  }) : user = null;

  bool get isSpecial => specialMention != null;
  String get username => isSpecial ? specialMention! : user!.username;
}

class MentionAutocomplete extends StatelessWidget {
  final List<MentionItem> items;
  final void Function(MentionItem item) onSelect;

  const MentionAutocomplete({
    super.key,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (context, index) {
            final item = items[index];
            if (item.isSpecial) {
              return _buildSpecialItem(item);
            }
            return _buildUserItem(item);
          },
        ),
      ),
    );
  }

  Widget _buildSpecialItem(MentionItem item) {
    return InkWell(
      onTap: () => onSelect(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.accent,
              child: Icon(Icons.campaign, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '@${item.specialMention}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    item.specialDescription ?? '',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(MentionItem item) {
    final user = item.user!;
    return InkWell(
      onTap: () => onSelect(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            UserAvatar(userId: user.id, radius: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserDisplayName(
                    userId: user.id,
                    displayName: user.displayName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    fallbackEmoji: user.customStatusEmoji,
                  ),
                  Text(
                    '@${user.username}',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
