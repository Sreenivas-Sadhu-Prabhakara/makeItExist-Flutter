
abstract class AuthEvent {}

class AuthCheckStatus extends AuthEvent {}

class AuthGoogleSignIn extends AuthEvent {}

class AuthFacebookSignIn extends AuthEvent {}

class AuthMicrosoftSignIn extends AuthEvent {}

class AuthEmailSignIn extends AuthEvent {
	final String email;
	final String password;
	AuthEmailSignIn({required this.email, required this.password});
}

class AuthLogout extends AuthEvent {}
