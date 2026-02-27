import '../../../core/error/exceptions.dart';
import '../../../domain/entities/user.dart';
import '../../models/user_model.dart';
import 'daos/user_dao.dart';
import 'mappers/user_mapper.dart';

class UserLocalDataSource {
  final UserDao _dao;

  UserLocalDataSource({required UserDao dao}) : _dao = dao;

  Future<void> cacheUsers(List<User> users) async {
    try {
      final companions = users
          .map((u) => UserMapper.toCompanion(
                u is UserModel
                    ? u
                    : UserModel(
                        id: u.id,
                        username: u.username,
                        email: u.email,
                        firstName: u.firstName,
                        lastName: u.lastName,
                        nickname: u.nickname,
                        position: u.position,
                        locale: u.locale,
                        createAt: u.createAt,
                        updateAt: u.updateAt,
                        deleteAt: u.deleteAt,
                        status: u.status,
                      ),
              ))
          .toList();
      await _dao.upsertUsers(companions);
    } catch (e) {
      throw CacheException(message: 'Failed to cache users: $e');
    }
  }

  Future<UserModel?> getUser(String id) async {
    try {
      final entry = await _dao.getUser(id);
      if (entry == null) return null;
      return UserMapper.fromEntry(entry);
    } catch (e) {
      throw CacheException(message: 'Failed to get cached user: $e');
    }
  }

  Future<List<UserModel>> getUsersByIds(List<String> ids) async {
    try {
      final entries = await _dao.getUsersByIds(ids);
      return entries.map(UserMapper.fromEntry).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get cached users: $e');
    }
  }
}
