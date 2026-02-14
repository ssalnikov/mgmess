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

  // Membership info
  final int msgCount;
  final int mentionCount;
  final int lastViewedAt;

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
    this.msgCount = 0,
    this.mentionCount = 0,
    this.lastViewedAt = 0,
  });

  int get unreadCount => totalMsgCount - msgCount;
  bool get hasUnread => unreadCount > 0;
  bool get hasMention => mentionCount > 0;
  bool get isDirect => type == ChannelType.direct;
  bool get isGroup => type == ChannelType.group;
  bool get isPrivate => type == ChannelType.private_;

  Channel copyWith({
    int? totalMsgCount,
    int? lastPostAt,
    int? msgCount,
    int? mentionCount,
    int? lastViewedAt,
    String? displayName,
  }) {
    return Channel(
      id: id,
      teamId: teamId,
      name: name,
      displayName: displayName ?? this.displayName,
      header: header,
      purpose: purpose,
      type: type,
      createAt: createAt,
      updateAt: updateAt,
      deleteAt: deleteAt,
      totalMsgCount: totalMsgCount ?? this.totalMsgCount,
      lastPostAt: lastPostAt ?? this.lastPostAt,
      msgCount: msgCount ?? this.msgCount,
      mentionCount: mentionCount ?? this.mentionCount,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
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
  List<Object?> get props => [id];
}
