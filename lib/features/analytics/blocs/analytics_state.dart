import 'package:equatable/equatable.dart';
import '../models/analytics_summary.dart';
import '../models/analytics_categories.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsSummaryLoaded extends AnalyticsState {
  final AnalyticsSummary summary;

  const AnalyticsSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class AnalyticsCategoriesLoaded extends AnalyticsState {
  final AnalyticsCategories categories;

  const AnalyticsCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
