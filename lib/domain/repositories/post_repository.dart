import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/post.dart';

abstract class PostRepository {
  Future<Either<Failure, List<Post>>> getChannelPosts(
    String channelId, {
    int page,
    int perPage,
    String? before,
    String? after,
  });
  Future<Either<Failure, Post>> createPost({
    required String channelId,
    required String message,
    String? rootId,
    List<String>? fileIds,
  });
  Future<Either<Failure, Post>> getPost(String postId);
  Future<Either<Failure, void>> deletePost(String postId);
  Future<Either<Failure, List<Post>>> getPostThread(String postId);
  Future<Either<Failure, List<Post>>> getFlaggedPosts(String userId, {
    int page,
    int perPage,
  });
  Future<Either<Failure, List<Post>>> searchPosts(
    String teamId,
    String terms,
  );
  Future<Either<Failure, void>> flagPost(String userId, String postId);
  Future<Either<Failure, void>> unflagPost(String userId, String postId);
}
