// repositories/ai_analyze_repository.dart
import '../../../services/api_client.dart';
import '../model/finance_analyze_request.dart';

class AiAnalyzeRepository {
  final ApiClient _apiClient;

  AiAnalyzeRepository(this._apiClient);

  Future<FinanceAnalyzeResponse> quickAnalyze(FinanceAnalyzeRequest req) async {
    final response = await _apiClient.dio.post(
      '/api/ai/quick-analyze',
      data: req.toJson(),
    );
    return FinanceAnalyzeResponse.fromJson(response.data);
  }

  Future<FinanceAnalyzeResponse> deepAnalyze(FinanceAnalyzeRequest req) async {
    final response = await _apiClient.dio.post(
      '/api/ai/deep-analyze',
      data: req.toJson(),
    );
    return FinanceAnalyzeResponse.fromJson(response.data);
  }
}
