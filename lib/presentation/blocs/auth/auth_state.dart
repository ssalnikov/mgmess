import 'package:equatable/equatable.dart';

import '../../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final String teamId;
  final String teamName;

  const AuthAuthenticated({
    required this.user,
    this.teamId = '',
    this.teamName = '',
  });

  @override
  List<Object?> get props => [user, teamId, teamName];
}

class AuthUnauthenticated extends AuthState {
  final String? message;

  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthConfigLoaded extends AuthState {
  final bool enableSignInWithEmail;
  final bool enableSignInWithUsername;
  final bool enableSignUpWithGitLab;

  const AuthConfigLoaded({
    required this.enableSignInWithEmail,
    required this.enableSignInWithUsername,
    required this.enableSignUpWithGitLab,
  });

  @override
  List<Object?> get props => [
        enableSignInWithEmail,
        enableSignInWithUsername,
        enableSignUpWithGitLab,
      ];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
