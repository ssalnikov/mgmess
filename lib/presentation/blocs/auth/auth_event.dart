import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckSession extends AuthEvent {
  const AuthCheckSession();
}

class AuthOAuthCompleted extends AuthEvent {
  final String token;
  final String? csrfToken;

  const AuthOAuthCompleted({required this.token, this.csrfToken});

  @override
  List<Object?> get props => [token, csrfToken];
}

class AuthLoginRequested extends AuthEvent {
  final String loginId;
  final String password;

  const AuthLoginRequested({required this.loginId, required this.password});

  @override
  List<Object?> get props => [loginId, password];
}

class AuthLoadConfig extends AuthEvent {
  const AuthLoadConfig();
}

class AuthTeamSwitched extends AuthEvent {
  final String teamId;
  final String teamName;

  const AuthTeamSwitched({required this.teamId, required this.teamName});

  @override
  List<Object?> get props => [teamId, teamName];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
