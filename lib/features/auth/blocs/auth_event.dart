import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  LoginRequested(this.username, this.password);

  @override
  List<Object> get props => [username, password];
}

class RegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  RegisterRequested(this.username, this.email, this.password);

  @override
  List<Object> get props => [username, email, password];
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  ForgotPasswordRequested(this.email);

  @override
  List<Object> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;
  ResetPasswordRequested(this.token, this.newPassword);
  @override
  List<Object> get props => [token, newPassword];
}

class ValidateResetToken extends AuthEvent {
  final String token;
  ValidateResetToken(this.token);
}

class LogoutRequested extends AuthEvent {}

class GoogleSignInRequested extends AuthEvent {}

class GuestLoginRequested extends AuthEvent {}

class RegisterFromGuestRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;

  RegisterFromGuestRequested(this.username, this.email, this.password);

  @override
  List<Object> get props => [username, email, password];
}
