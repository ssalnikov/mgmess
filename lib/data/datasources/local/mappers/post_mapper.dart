import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../domain/entities/file_info.dart';
import '../../../../domain/entities/post.dart';
import '../../../models/file_info_model.dart';
import '../../../models/post_model.dart';
import '../app_database.dart' as db;

class PostMapper {
  static db.PostsCompanion toCompanion(Post post, {bool isPending = false, int sendStatus = 0}) {
    return db.PostsCompanion(
      id: Value(post.id),
      channelId: Value(post.channelId),
      userId: Value(post.userId),
      rootId: Value(post.rootId),
      message: Value(post.message),
      createAt: Value(post.createAt),
      updateAt: Value(post.updateAt),
      deleteAt: Value(post.deleteAt),
      editAt: Value(post.editAt),
      type: Value(post.type),
      metadataJson: Value(jsonEncode(post.metadata)),
      fileIdsJson: Value(jsonEncode(post.fileIds)),
      filesJson: Value(jsonEncode(
        post.files.map((f) => _fileInfoToJson(f)).toList(),
      )),
      isPinned: Value(post.isPinned),
      replyCount: Value(post.replyCount),
      reactionsJson: Value(jsonEncode(post.reactions)),
      pendingId: Value(post.pendingId),
      priority: Value(post.priority),
      isPending: Value(isPending),
      sendStatus: Value(sendStatus),
    );
  }

  static PostModel fromEntry(db.Post entry) {
    final metadata = _decodeMap(entry.metadataJson);
    final fileIds = _decodeStringList(entry.fileIdsJson);
    final files = _decodeFiles(entry.filesJson);
    final reactions = _decodeReactions(entry.reactionsJson);

    return PostModel(
      id: entry.id,
      channelId: entry.channelId,
      userId: entry.userId,
      rootId: entry.rootId,
      message: entry.message,
      createAt: entry.createAt,
      updateAt: entry.updateAt,
      deleteAt: entry.deleteAt,
      editAt: entry.editAt,
      type: entry.type,
      metadata: metadata,
      fileIds: fileIds,
      files: files,
      isPinned: entry.isPinned,
      replyCount: entry.replyCount,
      reactions: reactions,
      pendingId: entry.pendingId,
      priority: entry.priority,
    );
  }

  static Map<String, dynamic> _decodeMap(String json) {
    try {
      return (jsonDecode(json) as Map).cast<String, dynamic>();
    } catch (_) {
      return {};
    }
  }

  static List<String> _decodeStringList(String json) {
    try {
      return (jsonDecode(json) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  static List<FileInfo> _decodeFiles(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => FileInfoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Map<String, List<String>> _decodeReactions(String json) {
    try {
      final map = jsonDecode(json) as Map;
      return map.map((k, v) {
        if (v is List) {
          return MapEntry(k as String, v.cast<String>());
        }
        // Backward compatibility: old format Map<String, int>
        return MapEntry(k as String, <String>[]);
      });
    } catch (_) {
      return {};
    }
  }

  static Map<String, dynamic> _fileInfoToJson(FileInfo f) {
    return {
      'id': f.id,
      'post_id': f.postId,
      'user_id': f.userId,
      'name': f.name,
      'extension': f.extension_,
      'size': f.size,
      'mime_type': f.mimeType,
      'width': f.width,
      'height': f.height,
      'has_preview_image': f.hasPreviewImage,
    };
  }
}
