import '../../domain/entities/user_thread.dart';
import 'post_model.dart';

class UserThreadModel extends UserThread {
  const UserThreadModel({
    required super.id,
    required super.replyCount,
    required super.lastReplyAt,
    required super.lastViewedAt,
    required super.participantIds,
    required super.post,
    required super.unreadReplies,
    required super.unreadMentions,
  });

  factory UserThreadModel.fromJson(Map<String, dynamic> json) {
    final postJson = json['post'] as Map<String, dynamic>? ?? {};
    final participants = json['participants'] as List<dynamic>? ?? [];

    return UserThreadModel(
      id: json['id'] as String? ?? '',
      replyCount: json['reply_count'] as int? ?? 0,
      lastReplyAt: json['last_reply_at'] as int? ?? 0,
      lastViewedAt: json['last_viewed_at'] as int? ?? 0,
      participantIds: participants
          .map((p) => (p is Map<String, dynamic>)
              ? (p['id'] as String? ?? '')
              : (p as String? ?? ''))
          .where((id) => id.isNotEmpty)
          .toList(),
      post: PostModel.fromJson(postJson),
      unreadReplies: json['unread_replies'] as int? ?? 0,
      unreadMentions: json['unread_mentions'] as int? ?? 0,
    );
  }
}
