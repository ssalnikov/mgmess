import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/seen_list.dart';

abstract class SeensRepository {
  Future<Either<Failure, SeenList>> getChannelSeens(String channelId);
  Future<Either<Failure, SeenList>> getPostSeens(String postId);
}
