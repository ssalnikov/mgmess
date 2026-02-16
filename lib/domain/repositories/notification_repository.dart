import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';

abstract class NotificationRepository {
  Future<Either<Failure, void>> registerDeviceToken(String token);
  Future<Either<Failure, void>> unregisterDevice();
}
