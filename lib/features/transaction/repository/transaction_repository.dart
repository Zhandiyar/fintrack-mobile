import 'package:dio/dio.dart';
import 'package:fintrack/features/transaction/models/transaction_type.dart';

import '../../analytics/models/period_type.dart';
import '../models/transaction_request.dart';
import '../models/transaction_response.dart';
import '../../../services/api_client.dart';

class TransactionRepository {
  final ApiClient _apiClient;

  TransactionRepository(this._apiClient);

  Future<List<TransactionResponseDto>> getTransactions({
    TransactionType? type,
    int? categoryId,
    PeriodType? periodType,
    int? year,
    int? month,
    int? day,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 0,
    int size = 20,
    String lang = 'ru',
  }) async {
    final queryParams = {
      if (type != null) 'type': transactionTypeToString(type),
      if (categoryId != null) 'categoryId': categoryId.toString(),
      if (periodType != null) 'periodType': periodType.asApiString(),
      if (year != null) 'year': year.toString(),
      if (month != null) 'month': month.toString(),
      if (day != null) 'day': day.toString(),
      if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
      if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
      'page': page.toString(),
      'size': size.toString(),
    };

    final response = await _apiClient.dio.get('/api/transactions',
      queryParameters: queryParams,
      options: Options(headers: {'Accept-Language': lang}),
    );

    final data = response.data['content'] as List;
    return data.map((e) => TransactionResponseDto.fromJson(e)).toList();
  }

  Future<TransactionResponseDto> getById(int id, String lang) async {
    final response = await _apiClient.dio.get(
      '/api/transactions/$id',
      options: Options(headers: {'Accept-Language': lang}),
    );
    return TransactionResponseDto.fromJson(response.data);
  }

  Future<TransactionResponseDto> create(TransactionRequestDto dto) async {
    final response = await _apiClient.dio.post('/api/transactions', data: dto.toJson());
    return TransactionResponseDto.fromJson(response.data);
  }

  Future<TransactionResponseDto> update(TransactionRequestDto dto) async {
    final response = await _apiClient.dio.put('/api/transactions', data: dto.toJson());
    return TransactionResponseDto.fromJson(response.data);
  }

  Future<void> delete(int id) async {
    await _apiClient.dio.delete('/api/transactions/$id');
  }
}
