abstract class AuthEvent {}

class AuthCheckStatus extends AuthEvent {}

class AuthLogin extends AuthEvent {
  final String email;
  final String password;

  AuthLogin({required this.email, required this.password});
}

class AuthRegister extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String studentId;
  final String? phone;

  AuthRegister({
    required this.email,
    required this.password,
    required this.fullName,
    required this.studentId,
    this.phone,
  });
}

class AuthVerifyOtp extends AuthEvent {
  final String email;
  final String otp;

  AuthVerifyOtp({required this.email, required this.otp});
}

class AuthLogout extends AuthEvent {}
