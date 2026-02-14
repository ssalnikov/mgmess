import '../../domain/entities/post.dart';
import 'file_info_model.dart';

class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.channelId,
    required super.userId,
    super.rootId,
    super.message,
    super.createAt,
    super.updateAt,
    super.deleteAt,
    super.editAt,
    super.type,
    super.metadata,
    super.fileIds,
    super.files,
    super.isPinned,
    super.isFlagged,
    super.replyCount,
    super.reactions,
    super.pendingId,
    super.forwardedPostMessage,
    super.forwardedChannelName,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};
    final filesJson = meta['files'] as List<dynamic>?;
    final reactionsJson = meta['reactions'] as List<dynamic>?;

    final Map<String, int> reactionMap = {};
    if (reactionsJson != null) {
      for (final r in reactionsJson) {
        final emoji = r['emoji_name'] as String? ?? '';
        reactionMap[emoji] = (reactionMap[emoji] ?? 0) + 1;
      }
    }

    // Parse forwarded post from permalink embed
    String forwardedMsg = '';
    String forwardedChannel = '';
    final embeds = meta['embeds'] as List<dynamic>?;
    if (embeds != null) {
      for (final embed in embeds) {
        if (embed is Map<String, dynamic> &&
            embed['type'] == 'permalink') {
          final data = embed['data'] as Map<String, dynamic>?;
          if (data != null) {
            final embedPost = data['post'] as Map<String, dynamic>?;
            forwardedMsg = embedPost?['message'] as String? ?? '';
            forwardedChannel =
                data['channel_display_name'] as String? ?? '';
            break;
          }
        }
      }
    }

    return PostModel(
      id: json['id'] as String? ?? '',
      channelId: json['channel_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      rootId: json['root_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createAt: json['create_at'] as int? ?? 0,
      updateAt: json['update_at'] as int? ?? 0,
      deleteAt: json['delete_at'] as int? ?? 0,
      editAt: json['edit_at'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      metadata: (json['props'] as Map?)?.cast<String, dynamic>() ?? {},
      fileIds: (json['file_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      files: filesJson
              ?.map((f) =>
                  FileInfoModel.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      isPinned: json['is_pinned'] as bool? ?? false,
      replyCount: json['reply_count'] as int? ?? 0,
      reactions: reactionMap,
      pendingId: json['pending_post_id'] as String? ?? '',
      forwardedPostMessage: forwardedMsg,
      forwardedChannelName: forwardedChannel,
    );
  }

  Map<String, dynamic> toJson() => {
        'channel_id': channelId,
        'message': message,
        if (rootId.isNotEmpty) 'root_id': rootId,
        if (fileIds.isNotEmpty) 'file_ids': fileIds,
      };
}
