import 'package:equatable/equatable.dart';

import '../models/period_type.dart';


abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnalyticsSummary extends AnalyticsEvent {
  final PeriodType periodType;
  final int year;
  final int? month;
  final int? day;

  const LoadAnalyticsSummary({
    required this.periodType,
    required this.year,
    this.month,
    this.day,
  });

  @override
  List<Object?> get props => [periodType, year, month, day];
}

class LoadAnalyticsCategories extends AnalyticsEvent {
  final PeriodType periodType;
  final int year;
  final int? month;
  final int? day;
  final String lang;

  const LoadAnalyticsCategories({
    required this.periodType,
    required this.year,
    this.month,
    this.day,
    this.lang = "ru",
  });

  @override
  List<Object?> get props => [periodType, year, month, day, lang];
}

class LoadAnalyticsCategoryDetails extends AnalyticsEvent {
  final String categoryName;
  final PeriodType periodType;
  final int year;
  final int? month;
  final int? day;
  final String lang;

  const LoadAnalyticsCategoryDetails({
    required this.categoryName,
    required this.periodType,
    required this.year,
    this.month,
    this.day,
    this.lang = "ru",
  });

  @override
  List<Object?> get props =>
      [categoryName, periodType, year, month, day, lang];
}
