import 'package:dio/dio.dart';
import '../../../services/api_client.dart';
import '../../../services/storage_service.dart';
import '../models/analytics_summary.dart';
import '../models/analytics_categories.dart';
import '../models/period_type.dart';


class AnalyticsRepository {
  final ApiClient _apiClient;

  AnalyticsRepository(this._apiClient);

  /// Получить общую сводку (summary)
  Future<AnalyticsSummary> getSummary({
    required PeriodType periodType,
    required int year,
    int? month,
    int? day,
  }) async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) {
      throw Exception('Отсутствует токен авторизации');
    }

    try {
      final queryParams = {
        'periodType': periodType.name,
        'year': year.toString(),
        if (month != null) 'month': month.toString(),
        if (day != null) 'day': day.toString(),
      };

      final response = await _apiClient.dio.get(
        '/api/analytics/summary',
        queryParameters: queryParams,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return AnalyticsSummary.fromJson(response.data);
    } catch (e) {
      print('Ошибка при получении сводки: $e');
      if (e is DioException) {
        print('Статус код: ${e.response?.statusCode}');
        print('Данные ответа: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Получить категории аналитики
  Future<AnalyticsCategories> getCategories({
    required PeriodType periodType,
    required int year,
    int? month,
    int? day,
    String lang = "ru",
  }) async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) {
      throw Exception('Отсутствует токен авторизации');
    }

    try {
      final queryParams = {
        'periodType': periodType.name,
        'year': year.toString(),
        if (month != null) 'month': month.toString(),
        if (day != null) 'day': day.toString(),
        'lang': lang,
      };

      final response = await _apiClient.dio.get(
        '/api/analytics/categories',
        queryParameters: queryParams,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return AnalyticsCategories.fromJson(response.data);
    } catch (e) {
      print('Ошибка при получении категорий: $e');
      if (e is DioException) {
        print('Статус код: ${e.response?.statusCode}');
        print('Данные ответа: ${e.response?.data}');
      }
      rethrow;
    }
  }
}
