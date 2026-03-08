import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/channel.dart';
import '../entities/channel_category.dart';
import '../entities/channel_member.dart';
import '../entities/channel_stats.dart';

abstract class ChannelRepository {
  Future<Either<Failure, List<Channel>>> getChannelsForUser(
    String userId,
    String teamId,
  );
  Future<Either<Failure, Channel>> getChannel(String channelId);
  Future<Either<Failure, ChannelStats>> getChannelStats(String channelId);
  Future<Either<Failure, List<ChannelMember>>> getChannelMembers(
    String channelId, {
    int page,
    int perPage,
  });
  Future<Either<Failure, void>> viewChannel(
    String userId,
    String channelId,
  );
  Future<Either<Failure, Channel>> createDirectChannel(
    String userId,
    String otherUserId,
  );
  Future<Either<Failure, Channel>> createChannel({
    required String teamId,
    required String name,
    required String displayName,
    required ChannelType type,
    String purpose,
    String header,
  });
  Future<Either<Failure, Channel>> createGroupChannel(
    List<String> userIds,
  );
  Future<Either<Failure, void>> muteChannel(
    String channelId,
    String userId,
  );
  Future<Either<Failure, void>> unmuteChannel(
    String channelId,
    String userId,
  );
  Future<Either<Failure, void>> leaveChannel(
    String channelId,
    String userId,
  );
  Future<Either<Failure, void>> removeChannelMember(
    String channelId,
    String userId,
  );
  Future<Either<Failure, void>> addChannelMember(
    String channelId,
    String userId,
  );
  Future<Either<Failure, void>> updateChannelMemberSchemeRoles(
    String channelId,
    String userId, {
    required bool schemeAdmin,
  });
  Future<Either<Failure, ({String roles, bool isMuted})>> getChannelMemberInfo(
    String channelId,
    String userId,
  );
  Future<Either<Failure, Channel>> updateChannel(
    String channelId,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, List<Channel>>> autocompleteChannels(
    String teamId,
    String term,
  );
  Future<Either<Failure, List<ChannelCategory>>> getChannelCategories(
    String userId,
    String teamId,
  );
  Future<Either<Failure, void>> updateChannelCategory(
    String userId,
    String teamId,
    String categoryId,
    Map<String, dynamic> data,
  );
}
