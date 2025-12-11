import 'package:fintrack/features/settings/blocs/settings_event.dart';
import 'package:fintrack/features/settings/blocs/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import '../repository/settings_repository.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;

  SettingsBloc(this._repository) : super(SettingsInitial()) {
    on<ChangePasswordEvent>(_onChangePassword);
    on<DeleteAccountEvent>(_onDeleteAccount);
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(SettingsLoading());
      await _repository.changePassword(
        event.currentPassword,
        event.newPassword,
      );
      emit(SettingsSuccess(message: 'Пароль успешно изменен'));
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] as String?;
      if (errorMessage?.toLowerCase().contains('неверный пароль') ?? false) {
        emit(SettingsError(message: 'Вы ввели неверно текущий пароль'));
      } else if (errorMessage?.toLowerCase().contains('не совпадает') ?? false) {
        emit(SettingsError(message: 'Новый пароль не должен совпадать с текущим'));
      } else {
        emit(SettingsError(message: errorMessage ?? 'Ошибка при изменении пароля'));
      }
    } catch (e) {
      emit(SettingsError(message: 'Произошла ошибка при изменении пароля'));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(SettingsLoading());
      await _repository.deleteAccount();
      emit(SettingsSuccess(message: 'Аккаунт успешно удален'));
    } catch (e) {
      emit(SettingsError(message: 'Произошла ошибка при удалении аккаунта'));
    }
  }
} 