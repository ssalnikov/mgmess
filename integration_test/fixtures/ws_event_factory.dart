import 'dart:convert';

import 'package:mgmess/core/network/websocket_events.dart';

/// Создаёт WsEvent для нового поста.
/// data.post — JSON string, как в реальном WS.
WsEvent createPostedEvent({
  required String postId,
  required String channelId,
  required String userId,
  required String message,
  int? createAt,
  String? senderName,
  String? channelDisplayName,
  String? rootId,
}) {
  final post = {
    'id': postId,
    'channel_id': channelId,
    'user_id': userId,
    'root_id': rootId ?? '',
    'message': message,
    'create_at': createAt ?? DateTime.now().millisecondsSinceEpoch,
    'update_at': 0,
    'delete_at': 0,
    'edit_at': 0,
    'type': '',
    'props': {},
    'file_ids': <String>[],
    'metadata': {},
  };

  return WsEvent(
    event: WsEventType.posted,
    data: {
      'post': jsonEncode(post),
      'channel_type': 'O',
      if (senderName != null) 'sender_name': senderName,
      if (channelDisplayName != null)
        'channel_display_name': channelDisplayName,
    },
    broadcast: {
      'channel_id': channelId,
      'user_id': userId,
    },
  );
}

/// Создаёт WsEvent для отредактированного поста.
WsEvent createPostEditedEvent({
  required String postId,
  required String channelId,
  required String userId,
  required String newMessage,
  int? editAt,
}) {
  final post = {
    'id': postId,
    'channel_id': channelId,
    'user_id': userId,
    'root_id': '',
    'message': newMessage,
    'create_at': 1700000001000,
    'update_at': DateTime.now().millisecondsSinceEpoch,
    'delete_at': 0,
    'edit_at': editAt ?? DateTime.now().millisecondsSinceEpoch,
    'type': '',
    'props': {},
    'file_ids': <String>[],
    'metadata': {},
  };

  return WsEvent(
    event: WsEventType.postEdited,
    data: {
      'post': jsonEncode(post),
    },
    broadcast: {
      'channel_id': channelId,
    },
  );
}

/// Создаёт WsEvent для удалённого поста.
WsEvent createPostDeletedEvent({
  required String postId,
  required String channelId,
  String rootId = '',
}) {
  final post = {
    'id': postId,
    'channel_id': channelId,
    'root_id': rootId,
    'delete_at': DateTime.now().millisecondsSinceEpoch,
  };

  return WsEvent(
    event: WsEventType.postDeleted,
    data: {
      'post': jsonEncode(post),
    },
    broadcast: {
      'channel_id': channelId,
    },
  );
}

/// Создаёт WsEvent для индикатора набора текста.
WsEvent createTypingEvent({
  required String channelId,
  required String userId,
}) {
  return WsEvent(
    event: WsEventType.typing,
    data: {
      'channel_id': channelId,
    },
    broadcast: {
      'channel_id': channelId,
      'user_id': userId,
    },
  );
}
