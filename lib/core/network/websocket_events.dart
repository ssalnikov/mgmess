class WsEventType {
  static const String hello = 'hello';
  static const String posted = 'posted';
  static const String postEdited = 'post_edited';
  static const String postDeleted = 'post_deleted';
  static const String typing = 'typing';
  static const String channelViewed = 'channel_viewed';
  static const String channelUpdated = 'channel_updated';
  static const String channelCreated = 'channel_created';
  static const String channelDeleted = 'channel_deleted';
  static const String channelMemberUpdated = 'channel_member_updated';
  static const String directAdded = 'direct_added';
  static const String groupAdded = 'group_added';
  static const String statusChange = 'status_change';
  static const String reactionAdded = 'reaction_added';
  static const String reactionRemoved = 'reaction_removed';
  static const String channelSeensUpdated = 'channel_seens_updated';
  static const String threadSeensUpdated = 'thread_seens_updated';
  static const String preferencesChanged = 'preferences_changed';
  static const String preferencesDeleted = 'preferences_deleted';
  static const String userUpdated = 'user_updated';
  static const String multipleChannelsViewed = 'multiple_channels_viewed';
  static const String newUser = 'new_user';
  static const String leaveTeam = 'leave_team';
  static const String updateTeam = 'update_team';
  static const String sidebarCategoryUpdated = 'sidebar_category_updated';
}

class WsEvent {
  final String event;
  final Map<String, dynamic> data;
  final Map<String, dynamic> broadcast;
  final int seq;

  const WsEvent({
    required this.event,
    required this.data,
    this.broadcast = const {},
    this.seq = 0,
  });

  factory WsEvent.fromJson(Map<String, dynamic> json) {
    return WsEvent(
      event: json['event'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      broadcast: json['broadcast'] as Map<String, dynamic>? ?? {},
      seq: json['seq'] as int? ?? 0,
    );
  }

  String? get channelId =>
      broadcast['channel_id'] as String? ??
      data['channel_id'] as String?;

  String? get userId =>
      broadcast['user_id'] as String? ?? data['user_id'] as String?;
}
