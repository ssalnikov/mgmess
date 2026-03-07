import 'package:dartz/dartz.dart';

import '../../core/config/app_config.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/user_local_datasource.dart';
import '../datasources/remote/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;

  UserRepositoryImpl({
    required UserRemoteDataSource remoteDataSource,
    required UserLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, User>> getUser(String userId) async {
    // Try local cache first
    try {
      final cached = await _localDataSource.getUser(userId);
      if (cached != null) return Right(cached);
    } catch (_) {}

    // Not in cache — fetch from API
    try {
      final user = await _remoteDataSource.getUser(userId);
      _localDataSource.cacheUsers([user]).catchError((_) {});
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<User>>> getUsersByIds(
    List<String> userIds,
  ) async {
    try {
      final users = await _remoteDataSource.getUsersByIds(userIds);
      _localDataSource.cacheUsers(users).catchError((_) {});
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, User>> updateUser(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    try {
      final user = await _remoteDataSource.updateUser(userId, patch);
      _localDataSource.cacheUsers([user]).catchError((_) {});
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> uploadUserImage(
    String userId,
    String filePath,
  ) async {
    try {
      await _remoteDataSource.uploadUserImage(userId, filePath);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<User>>> autocompleteUsers(
    String name, {
    String? teamId,
    String? channelId,
  }) async {
    try {
      final users = await _remoteDataSource.autocompleteUsers(
        name,
        teamId: teamId,
        channelId: channelId,
      );
      _localDataSource.cacheUsers(users).catchError((_) {});
      return Right(users.where((u) => !u.isDeleted).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> getUserStatuses(
    List<String> userIds,
  ) async {
    try {
      final statuses =
          await _remoteDataSource.getUserStatuses(userIds);
      return Right(statuses);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserStatus(
    String userId,
    String status,
  ) async {
    try {
      await _remoteDataSource.updateUserStatus(userId, status);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomStatus(
    String userId, {
    required String emoji,
    required String text,
  }) async {
    try {
      await _remoteDataSource.updateCustomStatus(userId, emoji: emoji, text: text);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomStatus(String userId) async {
    try {
      await _remoteDataSource.deleteCustomStatus(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  String getUserImageUrl(String userId) =>
      '${AppConfig.baseUrl}${ApiEndpoints.userImage(userId)}';
}
