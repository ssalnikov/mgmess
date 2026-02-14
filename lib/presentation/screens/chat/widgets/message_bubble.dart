import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/entities/post.dart';
import '../../../widgets/user_avatar.dart';
import 'file_attachment_widget.dart';

class MessageBubble extends StatelessWidget {
  final Post post;
  final bool isOwn;
  final bool showAvatar;
  final void Function(String postId)? onThreadTap;

  const MessageBubble({
    super.key,
    required this.post,
    required this.isOwn,
    required this.showAvatar,
    this.onThreadTap,
  });

  @override
  Widget build(BuildContext context) {
    if (post.isSystemMessage) {
      return _buildSystemMessage();
    }

    return Padding(
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
            child: GestureDetector(
              onTap: onThreadTap != null ? () => onThreadTap!(post.id) : null,
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
                          border: Border(
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
                        (f) => FileAttachmentWidget(fileInfo: f),
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
          if (isOwn) const SizedBox(width: 8),
        ],
      ),
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
