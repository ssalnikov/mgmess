import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/team.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, void>> saveAuthTokens({
    required String token,
    String? csrfToken,
  });
  Future<Either<Failure, void>> logout();
  Future<bool> hasValidSession();
  Future<Either<Failure, User>> login({
    required String loginId,
    required String password,
  });
  Future<Either<Failure, Map<String, dynamic>>> getClientConfig();
  Future<Either<Failure, List<Team>>> getMyTeams();
}
