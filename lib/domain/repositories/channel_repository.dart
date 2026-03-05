import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/channel.dart';
import '../entities/channel_stats.dart';
import '../entities/user.dart';

abstract class ChannelRepository {
  Future<Either<Failure, List<Channel>>> getChannelsForUser(
    String userId,
    String teamId,
  );
  Future<Either<Failure, Channel>> getChannel(String channelId);
  Future<Either<Failure, ChannelStats>> getChannelStats(String channelId);
  Future<Either<Failure, List<User>>> getChannelMembers(
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
  Future<Either<Failure, List<Channel>>> autocompleteChannels(
    String teamId,
    String term,
  );
}
