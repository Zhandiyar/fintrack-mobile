class FinanceAnalyzeRequest {
  final int year;
  final int month;
  final String currency;
  const FinanceAnalyzeRequest({
    required this.year,
    required this.month,
    required this.currency,
  });

  Map<String, dynamic> toJson() => {
    'year': year,
    'month': month,
    'currency': currency,
  };
}

// models/finance_analyze_response.dart
class FinanceAnalyzeResponse {
  final String analysis;

  const FinanceAnalyzeResponse({required this.analysis});

  factory FinanceAnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return FinanceAnalyzeResponse(
      analysis: json['analysis']?.toString() ?? 'Нет данных.',
    );
  }
}
