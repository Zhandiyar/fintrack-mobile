import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'category_summary.dart';

part 'analytics_categories.g.dart';

@JsonSerializable()
class AnalyticsCategories extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final List<CategorySummary> income;
  final List<CategorySummary> expense;

  const AnalyticsCategories({
    required this.totalIncome,
    required this.totalExpense,
    required this.income,
    required this.expense,
  });

  factory AnalyticsCategories.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsCategoriesFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsCategoriesToJson(this);

  @override
  List<Object?> get props => [income, expense];
}
