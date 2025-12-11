import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/ai_analyze_repository.dart';
import 'ai_analyze_event.dart';
import 'ai_analyze_state.dart';

class AiAnalyzeBloc extends Bloc<AiAnalyzeEvent, AiAnalyzeState> {
  final AiAnalyzeRepository repo;
  AiAnalyzeBloc(this.repo) : super(AiAnalyzeInitial()) {
    on<AiQuickAnalyzeRequested>(_onQuick);
    on<AiDeepAnalyzeRequested>(_onDeep);
  }

  Future<void> _onQuick(
      AiQuickAnalyzeRequested event, Emitter<AiAnalyzeState> emit) async {
    emit(AiAnalyzeLoading());
    try {
      final resp = await repo.quickAnalyze(event.request);
      emit(AiAnalyzeLoaded(resp));
    } catch (e) {
      emit(AiAnalyzeError('Ошибка AI-анализа: $e'));
    }
  }

  Future<void> _onDeep(
      AiDeepAnalyzeRequested event, Emitter<AiAnalyzeState> emit) async {
    emit(AiAnalyzeLoading());
    try {
      final resp = await repo.deepAnalyze(event.request);
      if (resp.analysis.trim().isEmpty) {
        emit(AiAnalyzeError("AI не смог провести анализ. Попробуйте позже."));
        return;
      }

      emit(AiAnalyzeLoaded(resp));
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        emit(AiAnalyzeError(
            'AI не смог выполнить анализ. Возможно, данных слишком мало или запрос был некорректным.'
        ));
      } else {
        emit(AiAnalyzeError('AI временно недоступен. Попробуйте позже.'));
      }
    }
  }
}