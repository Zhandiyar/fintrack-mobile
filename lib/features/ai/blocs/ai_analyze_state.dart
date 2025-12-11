import '../model/finance_analyze_request.dart';

abstract class AiAnalyzeState {}

class AiAnalyzeInitial extends AiAnalyzeState {}

class AiAnalyzeLoading extends AiAnalyzeState {}

class AiAnalyzeLoaded extends AiAnalyzeState {
  final FinanceAnalyzeResponse response;

  AiAnalyzeLoaded(this.response);
}

class AiAnalyzeError extends AiAnalyzeState {
  final String message;

  AiAnalyzeError(this.message);
}
