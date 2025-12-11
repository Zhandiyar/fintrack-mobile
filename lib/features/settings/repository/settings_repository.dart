import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../../../services/storage_service.dart';
import '../model/change_password_request.dart';

class SettingsRepository {
  final ApiClient _apiClient;
  SettingsRepository(this._apiClient);

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final body = ChangePasswordRequest(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    try {
      await _apiClient.dio.put(
        '/api/settings/change-password',
        data: body.toJson()
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка при изменении пароля');
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _apiClient.dio.delete('/api/settings/delete-account');
      await SecureStorage.clear(); // Удаляем токен после удаления аккаунта
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка при удалении аккаунта');
    }
  }
} 