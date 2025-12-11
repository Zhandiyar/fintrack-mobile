abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsSuccess extends SettingsState {
  final String message;

  SettingsSuccess({required this.message});
}

class SettingsError extends SettingsState {
  final String message;

  SettingsError({required this.message});
} 