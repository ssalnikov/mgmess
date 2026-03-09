import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/custom_emoji_cache.dart';
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
    final emojiChar = emojiMap[shortcode];
    final customUrl = emojiChar == null ? CustomEmojiCache.getUrl(shortcode) : null;

    final emojiSize = (style?.fontSize ?? 14) * 1.2;

    Widget emojiWidget;
    if (emojiChar != null) {
      emojiWidget = Text(
        emojiChar,
        style: TextStyle(fontSize: emojiSize * 0.75),
      );
    } else if (customUrl != null) {
      emojiWidget = _CustomEmojiIcon(url: customUrl, size: emojiSize);
    } else {
      // Unknown emoji — don't show anything rather than raw text
      return Text(
        displayName,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

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
        emojiWidget,
      ],
    );
  }
}

class _CustomEmojiIcon extends StatefulWidget {
  final String url;
  final double size;

  const _CustomEmojiIcon({required this.url, required this.size});

  @override
  State<_CustomEmojiIcon> createState() => _CustomEmojiIconState();
}

class _CustomEmojiIconState extends State<_CustomEmojiIcon> {
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = sl<SecureStorage>().getToken();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _tokenFuture,
      builder: (context, snapshot) {
        final token = snapshot.data;
        if (token == null) {
          return SizedBox(width: widget.size, height: widget.size);
        }
        return CachedNetworkImage(
          imageUrl: widget.url,
          httpHeaders: {'Authorization': 'Bearer $token'},
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          placeholder: (_, _) =>
              SizedBox(width: widget.size, height: widget.size),
          errorWidget: (_, _, _) =>
              SizedBox(width: widget.size, height: widget.size),
        );
      },
    );
  }
}
