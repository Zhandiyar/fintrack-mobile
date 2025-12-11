abstract class SettingsEvent {}

class ChangePasswordEvent extends SettingsEvent {
  final String currentPassword;
  final String newPassword;

  ChangePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
  });
}

class ResetPasswordEvent extends SettingsEvent {
  final String email;

  ResetPasswordEvent({required this.email});
}

class DeleteAccountEvent extends SettingsEvent {} 