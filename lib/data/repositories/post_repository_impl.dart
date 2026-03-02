import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/user_thread.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/local/post_local_datasource.dart';
import '../datasources/remote/post_remote_datasource.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource _remoteDataSource;
  final PostLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  PostRepositoryImpl({
    required PostRemoteDataSource remoteDataSource,
    required PostLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<Post>>> getChannelPosts(
    String channelId, {
    int page = 0,
    int perPage = 60,
    String? before,
    String? after,
  }) async {
    try {
      if (await _networkInfo.isConnected) {
        final posts = await _remoteDataSource.getChannelPosts(
          channelId,
          page: page,
          perPage: perPage,
          before: before,
          after: after,
        );
        // Cache in background
        _localDataSource.cachePosts(posts).catchError((e) {
          debugPrint('PostRepo: cache error: $e');
        });
        return Right(posts);
      } else {
        // Offline — read from cache
        final cached = await _localDataSource.getChannelPosts(
          channelId,
          limit: perPage,
          before: before,
        );
        return Right(cached);
      }
    } on ServerException catch (e) {
      // On server error, try cache as fallback
      try {
        final cached = await _localDataSource.getChannelPosts(
          channelId,
          limit: perPage,
          before: before,
        );
        if (cached.isNotEmpty) return Right(cached);
      } catch (_) {}
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Post>> createPost({
    required String channelId,
    required String message,
    String? rootId,
    List<String>? fileIds,
    String? priority,
  }) async {
    try {
      if (await _networkInfo.isConnected) {
        final post = await _remoteDataSource.createPost(
          channelId: channelId,
          message: message,
          rootId: rootId,
          fileIds: fileIds,
          priority: priority,
        );
        _localDataSource.cachePosts([post]).catchError((e) {
          debugPrint('PostRepo: cache error: $e');
        });
        return Right(post);
      } else {
        // Offline — save as pending
        final pendingId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
        final pendingPost = Post(
          id: pendingId,
          channelId: channelId,
          userId: '', // Will be filled on sync
          message: message,
          rootId: rootId ?? '',
          createAt: DateTime.now().millisecondsSinceEpoch,
          fileIds: fileIds ?? [],
          pendingId: pendingId,
          priority: priority ?? '',
        );
        await _localDataSource.savePendingPost(pendingPost);
        return Right(pendingPost);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Post>> getPost(String postId) async {
    try {
      final post = await _remoteDataSource.getPost(postId);
      return Right(post);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Post>> editPost(
    String postId,
    String message,
  ) async {
    try {
      final post = await _remoteDataSource.editPost(postId, message);
      _localDataSource.cachePosts([post]).catchError((e) {
        debugPrint('PostRepo: cache error: $e');
      });
      return Right(post);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(String postId) async {
    try {
      await _remoteDataSource.deletePost(postId);
      _localDataSource.deletePost(postId).catchError((e) {
        debugPrint('PostRepo: cache delete error: $e');
      });
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Post>>> getPostThread(
    String postId,
  ) async {
    try {
      final posts = await _remoteDataSource.getPostThread(postId);
      return Right(posts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Post>>> getFlaggedPosts(
    String userId, {
    int page = 0,
    int perPage = 60,
  }) async {
    try {
      final posts = await _remoteDataSource.getFlaggedPosts(
        userId,
        page: page,
        perPage: perPage,
      );
      return Right(posts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Post>>> searchPosts(
    String teamId,
    String terms,
  ) async {
    try {
      final posts =
          await _remoteDataSource.searchPosts(teamId, terms);
      return Right(posts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Post>>> getPinnedPosts(
    String channelId,
  ) async {
    try {
      final posts = await _remoteDataSource.getPinnedPosts(channelId);
      return Right(posts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Post>> pinPost(String postId) async {
    try {
      final post = await _remoteDataSource.pinPost(postId);
      return Right(post);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Post>> unpinPost(String postId) async {
    try {
      final post = await _remoteDataSource.unpinPost(postId);
      return Right(post);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addReaction(
    String postId,
    String userId,
    String emojiName,
  ) async {
    try {
      await _remoteDataSource.addReaction(
        userId: userId,
        postId: postId,
        emojiName: emojiName,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> removeReaction(
    String postId,
    String userId,
    String emojiName,
  ) async {
    try {
      await _remoteDataSource.removeReaction(
        userId: userId,
        postId: postId,
        emojiName: emojiName,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> flagPost(
    String userId,
    String postId,
  ) async {
    try {
      await _remoteDataSource.flagPost(userId, postId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<UserThread>>> getUserThreads(
    String userId,
    String teamId, {
    int perPage = 25,
    String? before,
  }) async {
    try {
      final threads = await _remoteDataSource.getUserThreads(
        userId,
        teamId,
        perPage: perPage,
        before: before,
      );
      return Right(threads);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> unflagPost(
    String userId,
    String postId,
  ) async {
    try {
      await _remoteDataSource.unflagPost(userId, postId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
