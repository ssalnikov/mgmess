import 'package:equatable/equatable.dart';

import 'file_info.dart';
import 'link_preview.dart';

class Post extends Equatable {
  final String id;
  final String channelId;
  final String userId;
  final String rootId;
  final String message;
  final int createAt;
  final int updateAt;
  final int deleteAt;
  final int editAt;
  final String type;
  final Map<String, dynamic> metadata;
  final List<String> fileIds;
  final List<FileInfo> files;
  final bool isPinned;
  final bool isFlagged;
  final int replyCount;
  final Map<String, List<String>> reactions;
  final String pendingId;
  final String forwardedPostMessage;
  final String forwardedChannelName;
  final String priority;
  final List<LinkPreview> linkPreviews;

  const Post({
    required this.id,
    required this.channelId,
    required this.userId,
    this.rootId = '',
    this.message = '',
    this.createAt = 0,
    this.updateAt = 0,
    this.deleteAt = 0,
    this.editAt = 0,
    this.type = '',
    this.metadata = const {},
    this.fileIds = const [],
    this.files = const [],
    this.isPinned = false,
    this.isFlagged = false,
    this.replyCount = 0,
    this.reactions = const {},
    this.pendingId = '',
    this.forwardedPostMessage = '',
    this.forwardedChannelName = '',
    this.priority = '',
    this.linkPreviews = const [],
  });

  bool get isDeleted => deleteAt > 0;
  bool get isEdited => editAt > 0;
  bool get isSystemMessage => type.isNotEmpty;
  bool get isReply => rootId.isNotEmpty;
  bool get hasFiles => fileIds.isNotEmpty;
  bool get isForwarded => forwardedPostMessage.isNotEmpty;
  bool get hasLinkPreviews => linkPreviews.isNotEmpty;
  bool get isUrgent => priority == 'urgent';
  bool get isImportant => priority == 'important';
  bool get hasPriority => priority.isNotEmpty;

  Post copyWith({
    String? message,
    int? editAt,
    int? deleteAt,
    bool? isPinned,
    bool? isFlagged,
    List<FileInfo>? files,
    Map<String, List<String>>? reactions,
    int? replyCount,
    String? priority,
  }) {
    return Post(
      id: id,
      channelId: channelId,
      userId: userId,
      rootId: rootId,
      message: message ?? this.message,
      createAt: createAt,
      updateAt: updateAt,
      deleteAt: deleteAt ?? this.deleteAt,
      editAt: editAt ?? this.editAt,
      type: type,
      metadata: metadata,
      fileIds: fileIds,
      files: files ?? this.files,
      isPinned: isPinned ?? this.isPinned,
      isFlagged: isFlagged ?? this.isFlagged,
      replyCount: replyCount ?? this.replyCount,
      reactions: reactions ?? this.reactions,
      pendingId: pendingId,
      forwardedPostMessage: forwardedPostMessage,
      forwardedChannelName: forwardedChannelName,
      priority: priority ?? this.priority,
      linkPreviews: linkPreviews,
    );
  }

  @override
  List<Object?> get props => [
        id,
        message,
        deleteAt,
        editAt,
        isPinned,
        isFlagged,
        replyCount,
        reactions,
        files,
        priority,
      ];
}
