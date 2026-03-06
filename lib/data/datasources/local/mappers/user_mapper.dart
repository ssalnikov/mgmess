import 'package:drift/drift.dart';

import '../../../models/user_model.dart';
import '../app_database.dart' as db;

class UserMapper {
  static db.UsersCompanion toCompanion(UserModel user) {
    return db.UsersCompanion(
      id: Value(user.id),
      username: Value(user.username),
      email: Value(user.email),
      firstName: Value(user.firstName),
      lastName: Value(user.lastName),
      nickname: Value(user.nickname),
      position: Value(user.position),
      locale: Value(user.locale),
      createAt: Value(user.createAt),
      updateAt: Value(user.updateAt),
      deleteAt: Value(user.deleteAt),
      status: Value(user.status),
      customStatusEmoji: Value(user.customStatusEmoji),
      customStatusText: Value(user.customStatusText),
    );
  }

  static UserModel fromEntry(db.User entry) {
    return UserModel(
      id: entry.id,
      username: entry.username,
      email: entry.email,
      firstName: entry.firstName,
      lastName: entry.lastName,
      nickname: entry.nickname,
      position: entry.position,
      locale: entry.locale,
      createAt: entry.createAt,
      updateAt: entry.updateAt,
      deleteAt: entry.deleteAt,
      status: entry.status,
      customStatusEmoji: entry.customStatusEmoji,
      customStatusText: entry.customStatusText,
    );
  }
}
