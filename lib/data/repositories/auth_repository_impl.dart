import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorage _secureStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorage secureStorage,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage;

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      await _secureStorage.saveUserId(user.id);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveAuthTokens({
    required String token,
    String? csrfToken,
  }) async {
    try {
      await _secureStorage.saveToken(token);
      if (csrfToken != null) {
        await _secureStorage.saveCsrfToken(csrfToken);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Best effort server logout
    }
    await _secureStorage.clearAll();
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> login({
    required String loginId,
    required String password,
  }) async {
    try {
      final (user, token) = await _remoteDataSource.login(
        loginId: loginId,
        password: password,
      );
      await _secureStorage.saveToken(token);
      await _secureStorage.saveUserId(user.id);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getClientConfig() async {
    try {
      final config = await _remoteDataSource.getClientConfig();
      return Right(config);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Team>>> getMyTeams() async {
    try {
      final teams = await _remoteDataSource.getMyTeams();
      return Right(teams);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> hasValidSession() async {
    final token = await _secureStorage.getToken();
    if (token == null) return false;
    try {
      await _remoteDataSource.getCurrentUser();
      return true;
    } catch (_) {
      return false;
    }
  }
}
