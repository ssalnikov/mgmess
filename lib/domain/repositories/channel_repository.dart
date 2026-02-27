import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/channel.dart';

abstract class ChannelRepository {
  Future<Either<Failure, List<Channel>>> getChannelsForUser(
    String userId,
    String teamId,
  );
  Future<Either<Failure, Channel>> getChannel(String channelId);
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
}
