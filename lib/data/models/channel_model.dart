import '../../domain/entities/channel.dart';

class ChannelModel extends Channel {
  const ChannelModel({
    required super.id,
    super.teamId,
    super.name,
    super.displayName,
    super.header,
    super.purpose,
    super.type,
    super.createAt,
    super.updateAt,
    super.deleteAt,
    super.totalMsgCount,
    super.lastPostAt,
    super.msgCount,
    super.mentionCount,
    super.lastViewedAt,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] as String? ?? '',
      teamId: json['team_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      header: json['header'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      type: Channel.typeFromString(json['type'] as String? ?? 'O'),
      createAt: json['create_at'] as int? ?? 0,
      updateAt: json['update_at'] as int? ?? 0,
      deleteAt: json['delete_at'] as int? ?? 0,
      totalMsgCount: json['total_msg_count'] as int? ?? 0,
      lastPostAt: json['last_post_at'] as int? ?? 0,
    );
  }

  factory ChannelModel.fromJsonWithMember(
    Map<String, dynamic> channelJson,
    Map<String, dynamic>? memberJson,
  ) {
    final channel = ChannelModel.fromJson(channelJson);
    if (memberJson == null) return channel;
    return ChannelModel(
      id: channel.id,
      teamId: channel.teamId,
      name: channel.name,
      displayName: channel.displayName,
      header: channel.header,
      purpose: channel.purpose,
      type: channel.type,
      createAt: channel.createAt,
      updateAt: channel.updateAt,
      deleteAt: channel.deleteAt,
      totalMsgCount: channel.totalMsgCount,
      lastPostAt: channel.lastPostAt,
      msgCount: memberJson['msg_count'] as int? ?? 0,
      mentionCount: memberJson['mention_count'] as int? ?? 0,
      lastViewedAt: memberJson['last_viewed_at'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'name': name,
        'display_name': displayName,
        'header': header,
        'purpose': purpose,
        'type': _typeToString(type),
        'create_at': createAt,
        'update_at': updateAt,
        'delete_at': deleteAt,
        'total_msg_count': totalMsgCount,
        'last_post_at': lastPostAt,
      };

  static String _typeToString(ChannelType type) {
    switch (type) {
      case ChannelType.open:
        return 'O';
      case ChannelType.private_:
        return 'P';
      case ChannelType.direct:
        return 'D';
      case ChannelType.group:
        return 'G';
    }
  }
}
