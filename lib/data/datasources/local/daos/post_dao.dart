import 'package:drift/drift.dart';

import '../app_database.dart';

class PostDao {
  final AppDatabase _db;

  PostDao(this._db);

  Future<void> upsertPosts(List<PostsCompanion> posts) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.posts, posts);
    });
  }

  Future<List<Post>> getChannelPosts(
    String channelId, {
    int limit = 60,
    String? before,
  }) async {
    final query = _db.select(_db.posts)
      ..where((t) => t.channelId.equals(channelId))
      ..orderBy([(t) => OrderingTerm.desc(t.createAt)])
      ..limit(limit);

    if (before != null) {
      // Get createAt of the "before" post
      final beforePost = await (_db.select(_db.posts)
            ..where((t) => t.id.equals(before)))
          .getSingleOrNull();
      if (beforePost != null) {
        query.where((t) => t.createAt.isSmallerThanValue(beforePost.createAt));
      }
    }

    return query.get();
  }

  Future<Post?> getPost(String id) async {
    return (_db.select(_db.posts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> deletePost(String id) async {
    await (_db.delete(_db.posts)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Post>> getPendingPosts() async {
    return (_db.select(_db.posts)
          ..where((t) => t.isPending.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.createAt)]))
        .get();
  }

  Future<void> markAsSent(String id) async {
    await (_db.update(_db.posts)..where((t) => t.id.equals(id))).write(
      const PostsCompanion(
        isPending: Value(false),
        sendStatus: Value(0),
      ),
    );
  }

  Future<void> markAsFailed(String id) async {
    await (_db.update(_db.posts)..where((t) => t.id.equals(id))).write(
      const PostsCompanion(sendStatus: Value(2)),
    );
  }
}
