import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/team.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  static const _selectedTeamKey = 'selected_team_id';

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckSession>(_onCheckSession);
    on<AuthOAuthCompleted>(_onOAuthCompleted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLoadConfig>(_onLoadConfig);
    on<AuthTeamSwitched>(_onTeamSwitched);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<({String id, String name, List<Team> teams})> _fetchTeamInfo() async {
    final result = await _authRepository.getMyTeams();
    return result.fold(
      (_) => (id: '', name: '', teams: <Team>[]),
      (teams) async {
        if (teams.isEmpty) return (id: '', name: '', teams: <Team>[]);

        // Try to restore previously selected team
        final prefs = await SharedPreferences.getInstance();
        final savedTeamId = prefs.getString(_selectedTeamKey);

        if (savedTeamId != null) {
          final saved = teams.where((t) => t.id == savedTeamId);
          if (saved.isNotEmpty) {
            final t = saved.first;
            return (id: t.id, name: t.name, teams: teams);
          }
        }

        return (
          id: teams.first.id,
          name: teams.first.name,
          teams: teams,
        );
      },
    );
  }

  Future<void> _onCheckSession(
    AuthCheckSession event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final hasSession = await _authRepository.hasValidSession();
    if (hasSession) {
      final result = await _authRepository.getCurrentUser();
      await result.fold(
        (failure) async =>
            emit(AuthUnauthenticated(message: failure.message)),
        (user) async {
          final team = await _fetchTeamInfo();
          emit(AuthAuthenticated(
            user: user,
            teamId: team.id,
            teamName: team.name,
            teams: team.teams,
          ));
        },
      );
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onOAuthCompleted(
    AuthOAuthCompleted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final saveResult = await _authRepository.saveAuthTokens(
      token: event.token,
      csrfToken: event.csrfToken,
    );
    if (saveResult.isLeft()) {
      emit(const AuthError(message: 'Failed to save auth tokens'));
      return;
    }
    final result = await _authRepository.getCurrentUser();
    await result.fold(
      (failure) async => emit(AuthError(message: failure.message)),
      (user) async {
        final team = await _fetchTeamInfo();
        emit(AuthAuthenticated(
          user: user,
          teamId: team.id,
          teamName: team.name,
          teams: team.teams,
        ));
      },
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.login(
      loginId: event.loginId,
      password: event.password,
    );
    await result.fold(
      (failure) async => emit(AuthError(message: failure.message)),
      (user) async {
        final team = await _fetchTeamInfo();
        emit(AuthAuthenticated(
          user: user,
          teamId: team.id,
          teamName: team.name,
          teams: team.teams,
        ));
      },
    );
  }

  Future<void> _onLoadConfig(
    AuthLoadConfig event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _authRepository.getClientConfig();
    result.fold(
      (failure) => emit(const AuthConfigLoaded(
        enableSignInWithEmail: true,
        enableSignInWithUsername: true,
        enableSignUpWithGitLab: true,
      )),
      (config) => emit(AuthConfigLoaded(
        enableSignInWithEmail: config['EnableSignInWithEmail'] == 'true',
        enableSignInWithUsername: config['EnableSignInWithUsername'] == 'true',
        enableSignUpWithGitLab: config['EnableSignUpWithGitLab'] == 'true',
      )),
    );
  }

  Future<void> _onTeamSwitched(
    AuthTeamSwitched event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthAuthenticated) return;

    // Persist selected team
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedTeamKey, event.teamId);

    emit(current.copyWith(
      teamId: event.teamId,
      teamName: event.teamName,
    ));
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    // Clear saved team on logout
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedTeamKey);
    emit(const AuthUnauthenticated());
  }
}
