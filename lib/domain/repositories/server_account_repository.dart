import '../entities/server_account.dart';

abstract class ServerAccountRepository {
  Future<List<ServerAccount>> getAll();
  Future<ServerAccount?> getActive();
  Future<void> add(ServerAccount account);
  Future<void> remove(String accountId);
  Future<void> setActive(String accountId);
  Future<void> update(ServerAccount account);
}
