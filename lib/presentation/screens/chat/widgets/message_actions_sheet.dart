import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/emoji_map.dart';
import '../../../../domain/entities/post.dart';

const _quickReactionNames = ['+1', 'heart', 'grinning', 'white_check_mark', 'eyes', 'raised_hands'];

class MessageActionsSheet extends StatelessWidget {
  final Post post;
  final bool isOwn;
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
          if (onReaction != null) _buildQuickReactions(context),
          if (post.message.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                HapticFeedback.selectionClick();
                Clipboard.setData(ClipboardData(text: post.message));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          if (post.message.isNotEmpty && onQuote != null)
            ListTile(
              leading: const Icon(Icons.format_quote),
              title: const Text('Quote'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onQuote!();
              },
            ),
          if (onForward != null)
            ListTile(
              leading: const Icon(Icons.shortcut),
              title: const Text('Forward'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onForward!();
              },
            ),
          if (!post.isPinned && onPin != null)
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: const Text('Pin'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onPin!();
              },
            ),
          if (post.isPinned && onUnpin != null)
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: const Text('Unpin'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onUnpin!();
              },
            ),
          if (isOwn && post.message.isNotEmpty && onEdit != null)
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onEdit!();
              },
            ),
          if (isOwn && onDelete != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
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
        children: _quickReactionNames.map((name) {
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
        }).toList(),
      ),
    );
  }
}
