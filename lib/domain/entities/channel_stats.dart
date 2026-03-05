import 'package:equatable/equatable.dart';

class ChannelStats extends Equatable {
  final String channelId;
  final int memberCount;
  final int guestCount;
  final int pinnedPostCount;

  const ChannelStats({
    required this.channelId,
    this.memberCount = 0,
    this.guestCount = 0,
    this.pinnedPostCount = 0,
  });

  @override
  List<Object?> get props => [channelId, memberCount, guestCount, pinnedPostCount];
}
