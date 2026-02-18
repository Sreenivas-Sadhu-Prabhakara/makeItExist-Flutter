import '../../../data/models/user_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated({required this.user});
}

class AuthUnauthenticated extends AuthState {}

class AuthNeedsVerification extends AuthState {
  final String email;
  final UserModel user;
  AuthNeedsVerification({required this.email, required this.user});
}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}
