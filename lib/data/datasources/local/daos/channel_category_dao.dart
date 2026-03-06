import 'package:drift/drift.dart';

import '../app_database.dart';

class ChannelCategoryDao {
  final AppDatabase _db;

  ChannelCategoryDao(this._db);

  Future<void> upsertCategories(
      List<ChannelCategoriesCompanion> categories) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.channelCategories, categories);
    });
  }

  Future<List<ChannelCategory>> getAllCategories() async {
    return (_db.select(_db.channelCategories)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<ChannelCategory>> getCategoriesByUser(String userId) async {
    return (_db.select(_db.channelCategories)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<void> deleteAllForUser(String userId) async {
    await (_db.delete(_db.channelCategories)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }

  Future<void> deleteCategory(String id) async {
    await (_db.delete(_db.channelCategories)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> updateCollapsed(String id, bool collapsed) async {
    await (_db.update(_db.channelCategories)
          ..where((t) => t.id.equals(id)))
        .write(ChannelCategoriesCompanion(collapsed: Value(collapsed)));
  }
}
