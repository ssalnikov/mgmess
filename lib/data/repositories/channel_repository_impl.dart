import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/channel.dart' show Channel, ChannelType;
import '../../domain/entities/channel_category.dart';
import '../../domain/entities/channel_member.dart';
import '../../domain/entities/channel_stats.dart';
import '../../domain/repositories/channel_repository.dart';
import '../datasources/local/channel_category_local_datasource.dart';
import '../datasources/local/channel_local_datasource.dart';
import '../datasources/remote/channel_remote_datasource.dart';
import '../datasources/remote/user_remote_datasource.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  final ChannelRemoteDataSource _remoteDataSource;
  final ChannelLocalDataSource _localDataSource;
  final ChannelCategoryLocalDataSource _categoryLocalDataSource;
  final NetworkInfo _networkInfo;
  final UserRemoteDataSource _userRemoteDataSource;

  ChannelRepositoryImpl({
    required ChannelRemoteDataSource remoteDataSource,
    required ChannelLocalDataSource localDataSource,
    required ChannelCategoryLocalDataSource categoryLocalDataSource,
    required NetworkInfo networkInfo,
    required UserRemoteDataSource userRemoteDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _categoryLocalDataSource = categoryLocalDataSource,
        _networkInfo = networkInfo,
        _userRemoteDataSource = userRemoteDataSource;

  @override
  Future<Either<Failure, List<Channel>>> getChannelsForUser(
    String userId,
    String teamId,
  ) async {
    try {
      if (await _networkInfo.isConnected) {
        final channels =
            await _remoteDataSource.getChannelsForUser(userId, teamId);

        // Fetch all memberships in one batch request
        final Map<String, Map<String, dynamic>> membersByChannelId = {};
        try {
          final members = await _remoteDataSource.getChannelMembersForUser(
            userId,
            teamId,
          );
          for (final m in members) {
            final chId = m['channel_id'] as String?;
            if (chId != null) membersByChannelId[chId] = m;
          }
        } catch (_) {
          // If batch fails, channels still show without unread info
        }

        final enriched = channels.map((channel) {
          final member = membersByChannelId[channel.id];
          if (member == null) return channel;

          bool isMuted = false;
          final notifyProps =
              member['notify_props'] as Map<String, dynamic>?;
          if (notifyProps != null) {
            isMuted = notifyProps['mark_unread'] == 'mention';
          }

          return channel.copyWith(
            msgCount: (member['msg_count'] as num?)?.toInt() ?? 0,
            msgCountRoot: (member['msg_count_root'] as num?)?.toInt() ?? 0,
            mentionCount: (member['mention_count'] as num?)?.toInt() ?? 0,
            mentionCountRoot:
                (member['mention_count_root'] as num?)?.toInt() ?? 0,
            urgentMentionCount:
                (member['urgent_mention_count'] as num?)?.toInt() ?? 0,
            lastViewedAt: (member['last_viewed_at'] as num?)?.toInt() ?? 0,
            isMuted: isMuted,
          );
        }).toList();

        // Cache in background
        _localDataSource.cacheChannels(enriched).catchError((e) {
          debugPrint('ChannelRepo: cache error: $e');
        });
        return Right(enriched);
      } else {
        // Offline — read from cache
        final cached = await _localDataSource.getAllChannels();
        return Right(cached);
      }
    } on ServerException catch (e) {
      // On server error, try cache as fallback
      try {
        final cached = await _localDataSource.getAllChannels();
        if (cached.isNotEmpty) return Right(cached);
      } catch (_) {}
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
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

  @override
  Future<Either<Failure, Channel>> createChannel({
    required String teamId,
    required String name,
    required String displayName,
    required ChannelType type,
    String purpose = '',
    String header = '',
  }) async {
    try {
      final typeStr = type == ChannelType.private_ ? 'P' : 'O';
      final channel = await _remoteDataSource.createChannel(
        teamId: teamId,
        name: name,
        displayName: displayName,
        type: typeStr,
        purpose: purpose,
        header: header,
      );
      return Right(channel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Channel>> createGroupChannel(
    List<String> userIds,
  ) async {
    try {
      final channel = await _remoteDataSource.createGroupChannel(userIds);
      return Right(channel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> muteChannel(
    String channelId,
    String userId,
  ) async {
    try {
      await _remoteDataSource.updateChannelNotifyProps(
        channelId,
        userId,
        {'mark_unread': 'mention'},
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> unmuteChannel(
    String channelId,
    String userId,
  ) async {
    try {
      await _remoteDataSource.updateChannelNotifyProps(
        channelId,
        userId,
        {'mark_unread': 'all'},
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ChannelStats>> getChannelStats(
    String channelId,
  ) async {
    try {
      final stats = await _remoteDataSource.getChannelStats(channelId);
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<ChannelMember>>> getChannelMembers(
    String channelId, {
    int page = 0,
    int perPage = 60,
  }) async {
    try {
      final members = await _remoteDataSource.getChannelMembers(
        channelId,
        page: page,
        perPage: perPage,
      );
      final userIds =
          members.map((m) => m['user_id'] as String).toList();
      if (userIds.isEmpty) return const Right([]);

      // Build roles map: userId -> roles string
      final rolesMap = <String, String>{};
      for (final m in members) {
        rolesMap[m['user_id'] as String] = m['roles'] as String? ?? '';
      }

      final users = await _userRemoteDataSource.getUsersByIds(userIds);
      final channelMembers = users
          .where((u) => !u.isDeleted)
          .map((u) => ChannelMember(
                user: u,
                roles: rolesMap[u.id] ?? '',
              ))
          .toList();
      return Right(channelMembers);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> leaveChannel(
    String channelId,
    String userId,
  ) async {
    try {
      await _remoteDataSource.leaveChannel(channelId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> removeChannelMember(
    String channelId,
    String userId,
  ) async {
    try {
      await _remoteDataSource.removeChannelMember(channelId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addChannelMember(
    String channelId,
    String userId,
  ) async {
    try {
      await _remoteDataSource.addChannelMember(channelId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateChannelMemberSchemeRoles(
    String channelId,
    String userId, {
    required bool schemeAdmin,
  }) async {
    try {
      await _remoteDataSource.updateChannelMemberSchemeRoles(
        channelId,
        userId,
        schemeAdmin: schemeAdmin,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ({String roles, bool isMuted})>> getChannelMemberInfo(
    String channelId,
    String userId,
  ) async {
    try {
      final data = await _remoteDataSource.getChannelMember(channelId, userId);
      final roles = data['roles'] as String? ?? '';
      final notifyProps = data['notify_props'] as Map<String, dynamic>?;
      final isMuted = notifyProps?['mark_unread'] == 'mention';
      return Right((roles: roles, isMuted: isMuted));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Channel>> updateChannel(
    String channelId,
    Map<String, dynamic> data,
  ) async {
    try {
      final channel = await _remoteDataSource.updateChannel(channelId, data);
      return Right(channel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Channel>>> autocompleteChannels(
    String teamId,
    String term,
  ) async {
    try {
      final channels =
          await _remoteDataSource.autocompleteChannels(teamId, term);
      return Right(channels);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<ChannelCategory>>> getChannelCategories(
    String userId,
    String teamId,
  ) async {
    try {
      if (await _networkInfo.isConnected) {
        final categories =
            await _remoteDataSource.getChannelCategories(userId, teamId);
        // Cache in background
        _categoryLocalDataSource
            .cacheCategories(categories, userId: userId)
            .catchError((e) {
          debugPrint('ChannelRepo: category cache error: $e');
        });
        return Right(categories);
      } else {
        final cached = await _categoryLocalDataSource.getCategories(userId);
        return Right(cached);
      }
    } on ServerException catch (e) {
      // On server error, try cache as fallback
      try {
        final cached = await _categoryLocalDataSource.getCategories(userId);
        if (cached.isNotEmpty) return Right(cached);
      } catch (_) {}
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateChannelCategory(
    String userId,
    String teamId,
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _remoteDataSource.updateChannelCategory(
        userId, teamId, categoryId, data,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
