import '../app_database.dart';

class UserDao {
  final AppDatabase _db;

  UserDao(this._db);

  Future<void> upsertUsers(List<UsersCompanion> users) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.users, users);
    });
  }

  Future<User?> getUser(String id) async {
    return (_db.select(_db.users)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<User>> getUsersByIds(List<String> ids) async {
    return (_db.select(_db.users)..where((t) => t.id.isIn(ids))).get();
  }
}
