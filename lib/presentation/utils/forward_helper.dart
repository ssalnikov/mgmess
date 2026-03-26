import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/post.dart';
import '../screens/chat/widgets/channel_picker_sheet.dart';

class ForwardHelper {
  static Future<void> forwardPost(
    BuildContext context, {
    required Post post,
    required String userId,
    required String teamId,
    required String teamName,
    String? excludeChannelId,
  }) async {
    final channel = await showModalBottomSheet<Channel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChannelPickerSheet(
        userId: userId,
        teamId: teamId,
        excludeChannelId: excludeChannelId,
      ),
    );
    if (channel == null || !context.mounted) return;

    final permalink =
        '${currentSession.serverUrl}/$teamName/pl/${post.id}';

    final result = await currentSession.postRepository.createPost(
      channelId: channel.id,
      message: permalink,
    );

    if (!context.mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Forward failed: ${failure.message}')),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message forwarded'),
            duration: Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
