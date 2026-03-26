import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/server_account.dart';
import '../../../domain/repositories/server_account_repository.dart';
import '../../../core/di/session_manager.dart';

class ServerListState extends Equatable {
  final List<ServerAccount> accounts;
  final String? activeAccountId;

  const ServerListState({
    this.accounts = const [],
    this.activeAccountId,
  });

  ServerListState copyWith({
    List<ServerAccount>? accounts,
    String? activeAccountId,
  }) =>
      ServerListState(
        accounts: accounts ?? this.accounts,
        activeAccountId: activeAccountId ?? this.activeAccountId,
      );

  @override
  List<Object?> get props => [accounts, activeAccountId];
}

class ServerListCubit extends Cubit<ServerListState> {
  final ServerAccountRepository _accountRepo;
  final SessionManager _sessionManager;

  ServerListCubit({
    required ServerAccountRepository accountRepo,
    required SessionManager sessionManager,
  })  : _accountRepo = accountRepo,
        _sessionManager = sessionManager,
        super(const ServerListState());

  Future<void> load() async {
    final accounts = await _accountRepo.getAll();
    final active = await _accountRepo.getActive();
    emit(ServerListState(
      accounts: accounts,
      activeAccountId: active?.id,
    ));
  }

  /// Switch active server. Creates session if needed.
  Future<void> switchServer(String accountId) async {
    if (accountId == state.activeAccountId) return;

    final account = state.accounts.firstWhere((a) => a.id == accountId);

    // Ensure session exists
    _sessionManager.createSession(account);
    _sessionManager.switchTo(accountId);
    await _accountRepo.setActive(accountId);

    // Update lastActiveAt
    final updated = account.copyWith(lastActiveAt: DateTime.now());
    await _accountRepo.update(updated);

    emit(state.copyWith(
      activeAccountId: accountId,
      accounts: state.accounts
          .map((a) => a.id == accountId ? updated : a)
          .toList(),
    ));
  }

  /// Add a new server account, create session, and switch to it.
  Future<void> addServer(ServerAccount account) async {
    await _accountRepo.add(account);
    _sessionManager.createSession(account);
    _sessionManager.switchTo(account.id);
    await _accountRepo.setActive(account.id);

    emit(ServerListState(
      accounts: [...state.accounts, account],
      activeAccountId: account.id,
    ));
  }

  /// Remove a server account and its session.
  Future<void> removeServer(String accountId) async {
    await _sessionManager.removeSession(accountId);
    await _accountRepo.remove(accountId);

    final remaining = state.accounts.where((a) => a.id != accountId).toList();
    final newActiveId = _sessionManager.activeSession?.accountId;

    // If we switched to another session, persist that
    if (newActiveId != null && newActiveId != state.activeAccountId) {
      await _accountRepo.setActive(newActiveId);
    }

    emit(ServerListState(
      accounts: remaining,
      activeAccountId: newActiveId,
    ));
  }
}
