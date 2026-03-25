import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/emoji_map.dart';
import '../../../../domain/entities/post.dart';
import 'emoji_picker_sheet.dart';

const _quickReactionNames = ['+1', 'heart', 'grinning', 'white_check_mark', 'eyes', 'raised_hands'];

class MessageActionsSheet extends StatelessWidget {
  final Post post;
  final bool isOwn;
  final bool canPost;
  final VoidCallback? onQuote;
  final VoidCallback? onForward;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onUnpin;
  final void Function(String emojiName)? onReaction;

  const MessageActionsSheet({
    super.key,
    required this.post,
    required this.isOwn,
    this.canPost = true,
    this.onQuote,
    this.onForward,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.onUnpin,
    this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Wrap(
        children: [
          if (canPost && onReaction != null) _buildQuickReactions(context),
          if (post.message.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(context.l10n.copy),
              onTap: () {
                HapticFeedback.selectionClick();
                Clipboard.setData(ClipboardData(text: post.message));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.copiedToClipboard),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          if (canPost && post.message.isNotEmpty && onQuote != null)
            ListTile(
              leading: const Icon(Icons.format_quote),
              title: Text(context.l10n.quote),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onQuote!();
              },
            ),
          if (onForward != null)
            ListTile(
              leading: const Icon(Icons.shortcut),
              title: Text(context.l10n.forward),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onForward!();
              },
            ),
          if (canPost && !post.isPinned && onPin != null)
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(context.l10n.pin),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onPin!();
              },
            ),
          if (canPost && post.isPinned && onUnpin != null)
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: Text(context.l10n.unpin),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onUnpin!();
              },
            ),
          if (canPost && isOwn && post.message.isNotEmpty && onEdit != null)
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(context.l10n.edit),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onEdit!();
              },
            ),
          if (canPost && isOwn && onDelete != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(context.l10n.delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onDelete!();
              },
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuickReactions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ..._quickReactionNames.map((name) {
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onReaction!(name);
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  emojiMap[name] ?? ':$name:',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => EmojiPickerSheet(
                  onEmojiSelected: onReaction!,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: const Icon(Icons.add, size: 22, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
