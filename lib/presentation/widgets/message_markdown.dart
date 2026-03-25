import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/di/injection.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/custom_emoji_cache.dart';
import '../../core/utils/emoji_utils.dart';

/// Reusable markdown widget for message text with emoji support.
/// Replaces :emoji_code: with Unicode (system) or inline images (custom).
class MessageMarkdown extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;

  const MessageMarkdown({
    super.key,
    required this.data,
    this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    CustomEmojiCache.ensureLoaded();

    final processed = replaceEmojis(
      data,
      customEmojiUrls: CustomEmojiCache.urls,
    );

    return MarkdownBody(
      data: processed,
      styleSheet: styleSheet,
      sizedImageBuilder: (config) {
        final url = config.uri.toString();
        if (url.contains('/emoji/') && url.contains('/image')) {
          return _CustomEmojiImage(url: url);
        }
        return Image.network(url);
      },
    );
  }
}

class _CustomEmojiImage extends StatefulWidget {
  final String url;

  const _CustomEmojiImage({required this.url});

  @override
  State<_CustomEmojiImage> createState() => _CustomEmojiImageState();
}

class _CustomEmojiImageState extends State<_CustomEmojiImage> {
  Map<String, String>? _headers;

  @override
  void initState() {
    super.initState();
    _loadHeaders();
  }

  Future<void> _loadHeaders() async {
    final token = await sl<SecureStorage>().getToken();
    if (mounted) {
      setState(() {
        _headers = {
          if (token != null) 'Authorization': 'Bearer $token',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_headers == null) {
      return const SizedBox(width: 20, height: 20);
    }
    return CachedNetworkImage(
      imageUrl: widget.url,
      width: 20,
      height: 20,
      httpHeaders: _headers!,
      errorWidget: (_, _, _) => const SizedBox(width: 20, height: 20),
      placeholder: (_, _) => const SizedBox(width: 20, height: 20),
    );
  }
}
