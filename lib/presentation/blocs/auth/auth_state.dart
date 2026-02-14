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

  const AuthAuthenticated({required this.user, this.teamId = ''});

  @override
  List<Object?> get props => [user, teamId];
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
