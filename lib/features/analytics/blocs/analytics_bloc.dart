import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/analytics_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;

  AnalyticsBloc(this.repository) : super(AnalyticsInitial()) {
    on<LoadAnalyticsSummary>(_onLoadAnalyticsSummary);
    on<LoadAnalyticsCategories>(_onLoadAnalyticsCategories);
  }

  Future<void> _onLoadAnalyticsSummary(
      LoadAnalyticsSummary event,
      Emitter<AnalyticsState> emit,
      ) async {
    try {
      emit(AnalyticsLoading());

      final summary = await repository.getSummary(
        periodType: event.periodType,
        year: event.year,
        month: event.month,
        day: event.day,
      );

      emit(AnalyticsSummaryLoaded(summary));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onLoadAnalyticsCategories(
      LoadAnalyticsCategories event,
      Emitter<AnalyticsState> emit,
      ) async {
    try {
      emit(AnalyticsLoading());

      final categories = await repository.getCategories(
        periodType: event.periodType,
        year: event.year,
        month: event.month,
        day: event.day,
        lang: event.lang,
      );

      emit(AnalyticsCategoriesLoaded(categories));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }
}
