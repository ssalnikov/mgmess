import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../core/l10n/l10n.dart';
import '../../domain/entities/channel.dart';
import '../../domain/entities/post.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../screens/chat/widgets/channel_picker_sheet.dart';

class ForwardHelper {
  static Future<Channel?> pickForwardChannel(
    BuildContext context, {
    required String userId,
    required String teamId,
    String? excludeChannelId,
  }) async {
    return showModalBottomSheet<Channel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChannelPickerSheet(
        userId: userId,
        teamId: teamId,
        excludeChannelId: excludeChannelId,
      ),
    );
  }

  static String buildPermalink({
    required String teamName,
    required String postId,
  }) {
    return '${currentSession.serverUrl}/$teamName/pl/$postId';
  }

  static Future<void> sendForward(
    BuildContext context, {
    required Post post,
    required String targetChannelId,
    required String userMessage,
  }) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final permalink = buildPermalink(
      teamName: authState.teamName,
      postId: post.id,
    );

    final message =
        userMessage.isNotEmpty ? '$permalink\n$userMessage' : permalink;

    final result = await currentSession.postRepository.createPost(
      channelId: targetChannelId,
      message: message,
    );

    if (!context.mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.forwardFailed(failure.message))),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.forwarded),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
