import 'package:equatable/equatable.dart';

enum ChannelType { open, private_, direct, group }

class Channel extends Equatable {
  final String id;
  final String teamId;
  final String name;
  final String displayName;
  final String header;
  final String purpose;
  final ChannelType type;
  final int createAt;
  final int updateAt;
  final int deleteAt;
  final int totalMsgCount;
  final int lastPostAt;

  // CRT (Collapsed Reply Threads) counters
  final int totalMsgCountRoot;
  final int msgCountRoot;
  final int mentionCountRoot;
  final int urgentMentionCount;

  // Membership info
  final int msgCount;
  final int mentionCount;
  final int lastViewedAt;
  final bool isMuted;

  const Channel({
    required this.id,
    this.teamId = '',
    this.name = '',
    this.displayName = '',
    this.header = '',
    this.purpose = '',
    this.type = ChannelType.open,
    this.createAt = 0,
    this.updateAt = 0,
    this.deleteAt = 0,
    this.totalMsgCount = 0,
    this.lastPostAt = 0,
    this.totalMsgCountRoot = 0,
    this.msgCountRoot = 0,
    this.mentionCountRoot = 0,
    this.urgentMentionCount = 0,
    this.msgCount = 0,
    this.mentionCount = 0,
    this.lastViewedAt = 0,
    this.isMuted = false,
  });

  int get unreadCount => isMuted ? 0 : totalMsgCountRoot - msgCountRoot;
  int get unreadCountRoot => totalMsgCountRoot - msgCountRoot;
  bool get hasUnread => !isMuted && (totalMsgCountRoot - msgCountRoot) > 0;
  bool get hasMention => mentionCountRoot > 0;
  bool get hasUrgent => urgentMentionCount > 0;
  bool get isDirect => type == ChannelType.direct;
  bool get isGroup => type == ChannelType.group;
  bool get isPrivate => type == ChannelType.private_;

  Channel copyWith({
    int? totalMsgCount,
    int? lastPostAt,
    int? totalMsgCountRoot,
    int? msgCountRoot,
    int? mentionCountRoot,
    int? urgentMentionCount,
    int? msgCount,
    int? mentionCount,
    int? lastViewedAt,
    String? displayName,
    String? header,
    String? purpose,
    String? name,
    bool? isMuted,
  }) {
    return Channel(
      id: id,
      teamId: teamId,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      header: header ?? this.header,
      purpose: purpose ?? this.purpose,
      type: type,
      createAt: createAt,
      updateAt: updateAt,
      deleteAt: deleteAt,
      totalMsgCount: totalMsgCount ?? this.totalMsgCount,
      lastPostAt: lastPostAt ?? this.lastPostAt,
      totalMsgCountRoot: totalMsgCountRoot ?? this.totalMsgCountRoot,
      msgCountRoot: msgCountRoot ?? this.msgCountRoot,
      mentionCountRoot: mentionCountRoot ?? this.mentionCountRoot,
      urgentMentionCount: urgentMentionCount ?? this.urgentMentionCount,
      msgCount: msgCount ?? this.msgCount,
      mentionCount: mentionCount ?? this.mentionCount,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  static ChannelType typeFromString(String type) {
    switch (type) {
      case 'O':
        return ChannelType.open;
      case 'P':
        return ChannelType.private_;
      case 'D':
        return ChannelType.direct;
      case 'G':
        return ChannelType.group;
      default:
        return ChannelType.open;
    }
  }

  @override
  List<Object?> get props => [
        id,
        totalMsgCount,
        lastPostAt,
        totalMsgCountRoot,
        msgCountRoot,
        mentionCountRoot,
        urgentMentionCount,
        msgCount,
        mentionCount,
        isMuted,
      ];
}
