import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/channel.dart';
import '../../domain/repositories/channel_repository.dart';
import '../datasources/remote/channel_remote_datasource.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  final ChannelRemoteDataSource _remoteDataSource;

  ChannelRepositoryImpl({
    required ChannelRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<Channel>>> getChannelsForUser(
    String userId,
    String teamId,
  ) async {
    try {
      final channels =
          await _remoteDataSource.getChannelsForUser(userId, teamId);

      // Enrich each channel with membership info
      final enriched = <Channel>[];
      for (final channel in channels) {
        try {
          final member = await _remoteDataSource.getChannelMember(
            channel.id,
            userId,
          );
          enriched.add(channel.copyWith(
            msgCount: member['msg_count'] as int? ?? 0,
            mentionCount: member['mention_count'] as int? ?? 0,
            lastViewedAt: member['last_viewed_at'] as int? ?? 0,
          ));
        } catch (_) {
          enriched.add(channel);
        }
      }
      return Right(enriched);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Channel>> getChannel(String channelId) async {
    try {
      final channel = await _remoteDataSource.getChannel(channelId);
      return Right(channel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> viewChannel(
    String userId,
    String channelId,
  ) async {
    try {
      await _remoteDataSource.viewChannel(userId, channelId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Channel>> createDirectChannel(
    String userId,
    String otherUserId,
  ) async {
    try {
      final channel = await _remoteDataSource.createDirectChannel(
        userId,
        otherUserId,
      );
      return Right(channel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
