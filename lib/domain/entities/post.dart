import 'package:equatable/equatable.dart';

import 'file_info.dart';

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
  final Map<String, int> reactions;
  final String pendingId;

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
  });

  bool get isDeleted => deleteAt > 0;
  bool get isEdited => editAt > 0;
  bool get isSystemMessage => type.isNotEmpty;
  bool get isReply => rootId.isNotEmpty;
  bool get hasFiles => fileIds.isNotEmpty;

  Post copyWith({
    String? message,
    int? editAt,
    int? deleteAt,
    bool? isPinned,
    bool? isFlagged,
    List<FileInfo>? files,
    Map<String, int>? reactions,
    int? replyCount,
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
    );
  }

  @override
  List<Object?> get props => [id];
}
