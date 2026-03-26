import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/server_account.dart';
import '../../domain/repositories/server_account_repository.dart';

class ServerAccountRepositoryImpl implements ServerAccountRepository {
  static const _accountsKey = 'server_accounts';
  static const _activeKey = 'active_server_id';

  @override
  Future<List<ServerAccount>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ServerAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ServerAccount?> getActive() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_activeKey);
    if (activeId == null) return null;
    final accounts = await getAll();
    try {
      return accounts.firstWhere((a) => a.id == activeId);
    } on StateError {
      return accounts.isNotEmpty ? accounts.first : null;
    }
  }

  @override
  Future<void> add(ServerAccount account) async {
    final accounts = await getAll();
    accounts.add(account);
    await _saveAll(accounts);
  }

  @override
  Future<void> remove(String accountId) async {
    final accounts = await getAll();
    accounts.removeWhere((a) => a.id == accountId);
    await _saveAll(accounts);

    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_activeKey);
    if (activeId == accountId) {
      if (accounts.isNotEmpty) {
        await prefs.setString(_activeKey, accounts.first.id);
      } else {
        await prefs.remove(_activeKey);
      }
    }
  }

  @override
  Future<void> setActive(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, accountId);
  }

  @override
  Future<void> update(ServerAccount account) async {
    final accounts = await getAll();
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      accounts[index] = account;
      await _saveAll(accounts);
    }
  }

  Future<void> _saveAll(List<ServerAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_accountsKey, json);
  }
}
