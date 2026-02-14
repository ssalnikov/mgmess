import 'package:dartz/dartz.dart';

import '../../core/config/app_config.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/remote/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final Map<String, User> _cache = {};

  UserRepositoryImpl({required UserRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, User>> getUser(String userId) async {
    if (_cache.containsKey(userId)) {
      return Right(_cache[userId]!);
    }
    try {
      final user = await _remoteDataSource.getUser(userId);
      _cache[userId] = user;
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
      for (final user in users) {
        _cache[user.id] = user;
      }
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
      _cache[userId] = user;
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
  String getUserImageUrl(String userId) =>
      '${AppConfig.baseUrl}${ApiEndpoints.userImage(userId)}';
}
