import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/user_thread.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/remote/post_remote_datasource.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource _remoteDataSource;

  PostRepositoryImpl({required PostRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<Post>>> getChannelPosts(
    String channelId, {
    int page = 0,
    int perPage = 60,
    String? before,
    String? after,
  }) async {
    try {
      final posts = await _remoteDataSource.getChannelPosts(
        channelId,
        page: page,
        perPage: perPage,
        before: before,
        after: after,
      );
      return Right(posts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Post>> createPost({
    required String channelId,
    required String message,
    String? rootId,
    List<String>? fileIds,
  }) async {
    try {
      final post = await _remoteDataSource.createPost(
        channelId: channelId,
        message: message,
        rootId: rootId,
        fileIds: fileIds,
      );
      return Right(post);
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
  Future<Either<Failure, void>> deletePost(String postId) async {
    try {
      await _remoteDataSource.deletePost(postId);
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
