import 'package:equatable/equatable.dart';

import 'post.dart';

class UserThread extends Equatable {
  final String id;
  final int replyCount;
  final int lastReplyAt;
  final int lastViewedAt;
  final List<String> participantIds;
  final Post post;
  final int unreadReplies;
  final int unreadMentions;

  const UserThread({
    required this.id,
    required this.replyCount,
    required this.lastReplyAt,
    required this.lastViewedAt,
    required this.participantIds,
    required this.post,
    required this.unreadReplies,
    required this.unreadMentions,
  });

  bool get hasUnread => unreadReplies > 0;

  @override
  List<Object?> get props => [id];
}
