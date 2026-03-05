import '../../domain/entities/channel_stats.dart';

class ChannelStatsModel extends ChannelStats {
  const ChannelStatsModel({
    required super.channelId,
    super.memberCount,
    super.guestCount,
    super.pinnedPostCount,
  });

  factory ChannelStatsModel.fromJson(Map<String, dynamic> json) {
    return ChannelStatsModel(
      channelId: json['channel_id'] as String? ?? '',
      memberCount: json['member_count'] as int? ?? 0,
      guestCount: json['guest_count'] as int? ?? 0,
      pinnedPostCount: json['pinnedpost_count'] as int? ?? 0,
    );
  }
}
