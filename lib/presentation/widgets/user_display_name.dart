import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/emoji_map.dart';
import '../blocs/user_status/user_status_cubit.dart';

class UserDisplayName extends StatelessWidget {
  final String userId;
  final String displayName;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;
  /// Fallback emoji from User entity (used when cubit has no data yet).
  final String? fallbackEmoji;

  const UserDisplayName({
    super.key,
    required this.userId,
    required this.displayName,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.fallbackEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final customStatus =
        context.select<UserStatusCubit, CustomStatus?>((cubit) {
      return cubit.state.customStatuses[userId];
    });

    final emojiCode = customStatus?.emoji ??
        (fallbackEmoji?.isNotEmpty == true ? fallbackEmoji! : '');
    if (emojiCode.isEmpty) {
      return Text(
        displayName,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final shortcode = emojiCode.replaceAll(':', '');
    final emojiChar = emojiMap[shortcode] ?? emojiCode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            displayName,
            style: style,
            maxLines: maxLines,
            overflow: overflow,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          emojiChar,
          style: TextStyle(fontSize: (style?.fontSize ?? 14) * 0.9),
        ),
      ],
    );
  }
}
