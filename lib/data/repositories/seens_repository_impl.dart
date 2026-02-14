import 'package:dartz/dartz.dart';

import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/seen_list.dart';
import '../../domain/repositories/seens_repository.dart';
import '../datasources/remote/seens_remote_datasource.dart';

class SeensRepositoryImpl implements SeensRepository {
  final SeensRemoteDataSource _remoteDataSource;

  SeensRepositoryImpl({required SeensRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, SeenList>> getChannelSeens(
    String channelId,
  ) async {
    try {
      final seens =
          await _remoteDataSource.getChannelSeens(channelId);
      return Right(seens);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, SeenList>> getPostSeens(
    String postId,
  ) async {
    try {
      final seens = await _remoteDataSource.getPostSeens(postId);
      return Right(seens);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
