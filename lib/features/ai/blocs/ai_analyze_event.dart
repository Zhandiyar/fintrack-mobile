import '../model/finance_analyze_request.dart';

abstract class AiAnalyzeEvent {}

class AiQuickAnalyzeRequested extends AiAnalyzeEvent {
  final FinanceAnalyzeRequest request;

  AiQuickAnalyzeRequested(this.request);
}

class AiDeepAnalyzeRequested extends AiAnalyzeEvent {
  final FinanceAnalyzeRequest request;

  AiDeepAnalyzeRequested(this.request);
}
