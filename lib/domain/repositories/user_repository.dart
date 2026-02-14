import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/user.dart';

abstract class UserRepository {
  Future<Either<Failure, User>> getUser(String userId);
  Future<Either<Failure, List<User>>> getUsersByIds(List<String> userIds);
  Future<Either<Failure, User>> updateUser(String userId, Map<String, dynamic> patch);
  Future<Either<Failure, void>> uploadUserImage(String userId, String filePath);
  Future<Either<Failure, Map<String, String>>> getUserStatuses(List<String> userIds);
  String getUserImageUrl(String userId);
}
