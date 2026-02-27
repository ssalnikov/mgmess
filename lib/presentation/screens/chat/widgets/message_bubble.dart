import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/entities/post.dart';
import '../../../widgets/user_avatar.dart';
import 'file_attachment_widget.dart';
import 'message_actions_sheet.dart';
import 'swipe_to_reply.dart';

class MessageBubble extends StatelessWidget {
  final Post post;
  final bool isOwn;
  final bool showAvatar;
  final void Function(String postId)? onThreadTap;
  final void Function(Post post)? onQuote;
  final void Function(Post post)? onForward;
  final void Function(Post post)? onEdit;
  final void Function(Post post)? onDelete;
  final void Function(Post post)? onPin;
  final void Function(Post post)? onUnpin;
  final bool isHighlighted;

  const MessageBubble({
    super.key,
    required this.post,
    required this.isOwn,
    required this.showAvatar,
    this.onThreadTap,
    this.onQuote,
    this.onForward,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.onUnpin,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (post.isSystemMessage) {
      return _buildSystemMessage();
    }

    return SwipeToReply(
      onReply: () => onQuote?.call(post),
      enabled: !post.isSystemMessage && onQuote != null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwn && showAvatar)
            GestureDetector(
              onTap: () => context.push(
                RouteNames.userProfilePath(post.userId),
              ),
              child: UserAvatar(userId: post.userId, radius: 16),
            )
          else if (!isOwn)
            const SizedBox(width: 32),
          const SizedBox(width: 8),
          Flexible(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(isHighlighted),
              tween: Tween(begin: isHighlighted ? 1.0 : 0.0, end: 0.0),
              duration: Duration(milliseconds: isHighlighted ? 2000 : 0),
              curve: isHighlighted ? Curves.easeIn : Curves.linear,
              builder: (context, value, child) {
                return Container(
                  decoration: value > 0
                      ? BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.3 * value),
                          borderRadius: BorderRadius.circular(18),
                        )
                      : null,
                  child: child,
                );
              },
              child: GestureDetector(
              onTap: onThreadTap != null ? () => onThreadTap!(post.id) : null,
              onLongPress: () => _showActions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isOwn
                      ? AppColors.messageBubbleOwn
                      : AppColors.messageBubbleOther,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomRight:
                        isOwn ? const Radius.circular(4) : null,
                    bottomLeft:
                        !isOwn ? const Radius.circular(4) : null,
                  ),
                  border: post.hasPriority
                      ? Border(
                          left: BorderSide(
                            color: post.isUrgent
                                ? AppColors.priorityUrgent
                                : AppColors.priorityImportant,
                            width: 3,
                          ),
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.hasPriority) ...[
                      _buildPriorityBadge(),
                      const SizedBox(height: 4),
                    ],
                    if (post.isPinned) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.push_pin,
                              size: 12, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            'Pinned',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (post.isForwarded) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shortcut,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              post.forwardedChannelName.isNotEmpty
                                  ? 'Forwarded from #${post.forwardedChannelName}'
                                  : 'Forwarded',
                              style: AppTextStyles.caption.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.accent,
                              width: 2,
                            ),
                          ),
                          color: Colors.black.withValues(alpha: 0.03),
                        ),
                        child: MarkdownBody(
                          data: post.forwardedPostMessage,
                          styleSheet: MarkdownStyleSheet(
                            p: AppTextStyles.body,
                          ),
                        ),
                      ),
                      if (post.message.isNotEmpty)
                        const SizedBox(height: 4),
                    ],
                    if (post.message.isNotEmpty)
                      MarkdownBody(
                        data: post.message,
                        styleSheet: MarkdownStyleSheet(
                          p: AppTextStyles.body,
                        ),
                      ),
                    if (post.hasFiles) ...[
                      const SizedBox(height: 4),
                      ...post.files.map(
                        (f) => FileAttachmentWidget(
                          fileInfo: f,
                          allMediaFiles: post.files
                              .where((fi) => fi.isImage || fi.isVideo)
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormatter.formatMessageTime(
                              post.createAt),
                          style: AppTextStyles.timestamp,
                        ),
                        if (post.isEdited) ...[
                          const SizedBox(width: 4),
                          const Text('(edited)',
                              style: AppTextStyles.timestamp),
                        ],
                      ],
                    ),
                    if (post.replyCount > 0 && onThreadTap != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.reply,
                              size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            '${post.replyCount} ${post.replyCount == 1 ? 'reply' : 'replies'}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          ),
          if (isOwn) const SizedBox(width: 8),
        ],
      ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      builder: (_) => MessageActionsSheet(
        post: post,
        isOwn: isOwn,
        onQuote: onQuote != null ? () => onQuote!(post) : null,
        onForward: onForward != null ? () => onForward!(post) : null,
        onEdit: onEdit != null ? () => onEdit!(post) : null,
        onDelete: onDelete != null ? () => onDelete!(post) : null,
        onPin: onPin != null ? () => onPin!(post) : null,
        onUnpin: onUnpin != null ? () => onUnpin!(post) : null,
      ),
    );
  }

  Widget _buildPriorityBadge() {
    final isUrgent = post.isUrgent;
    final color =
        isUrgent ? AppColors.priorityUrgent : AppColors.priorityImportant;
    final label = isUrgent ? 'Urgent' : 'Important';
    final icon = isUrgent ? Icons.priority_high : Icons.error_outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          post.message,
          style: AppTextStyles.caption.copyWith(
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
