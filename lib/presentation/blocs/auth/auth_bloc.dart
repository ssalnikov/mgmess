import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckSession>(_onCheckSession);
    on<AuthOAuthCompleted>(_onOAuthCompleted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLoadConfig>(_onLoadConfig);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<String> _fetchTeamId() async {
    final result = await _authRepository.getMyTeams();
    return result.fold(
      (_) => '',
      (teams) => teams.isNotEmpty ? teams.first.id : '',
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
          final teamId = await _fetchTeamId();
          emit(AuthAuthenticated(user: user, teamId: teamId));
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
        final teamId = await _fetchTeamId();
        emit(AuthAuthenticated(user: user, teamId: teamId));
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
        final teamId = await _fetchTeamId();
        emit(AuthAuthenticated(user: user, teamId: teamId));
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
        enableSignInWithEmail: false,
        enableSignInWithUsername: false,
        enableSignUpWithGitLab: true,
      )),
      (config) => emit(AuthConfigLoaded(
        enableSignInWithEmail: config['EnableSignInWithEmail'] == 'true',
        enableSignInWithUsername: config['EnableSignInWithUsername'] == 'true',
        enableSignUpWithGitLab: config['EnableSignUpWithGitlab'] == 'true',
      )),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}
