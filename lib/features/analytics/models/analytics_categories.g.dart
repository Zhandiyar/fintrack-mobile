// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_categories.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyticsCategories _$AnalyticsCategoriesFromJson(Map<String, dynamic> json) =>
    AnalyticsCategories(
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpense: (json['totalExpense'] as num).toDouble(),
      income: (json['income'] as List<dynamic>)
          .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      expense: (json['expense'] as List<dynamic>)
          .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnalyticsCategoriesToJson(
        AnalyticsCategories instance) =>
    <String, dynamic>{
      'totalIncome': instance.totalIncome,
      'totalExpense': instance.totalExpense,
      'income': instance.income,
      'expense': instance.expense,
    };
