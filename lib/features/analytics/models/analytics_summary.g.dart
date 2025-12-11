// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyticsSummary _$AnalyticsSummaryFromJson(Map<String, dynamic> json) =>
    AnalyticsSummary(
      currentIncome: (json['currentIncome'] as num).toDouble(),
      currentExpense: (json['currentExpense'] as num).toDouble(),
      netIncome: (json['netIncome'] as num).toDouble(),
      incomeChange: (json['incomeChange'] as num).toDouble(),
      expenseChange: (json['expenseChange'] as num).toDouble(),
      chartData: (json['chartData'] as List<dynamic>)
          .map((e) => ChartPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnalyticsSummaryToJson(AnalyticsSummary instance) =>
    <String, dynamic>{
      'currentIncome': instance.currentIncome,
      'currentExpense': instance.currentExpense,
      'netIncome': instance.netIncome,
      'incomeChange': instance.incomeChange,
      'expenseChange': instance.expenseChange,
      'chartData': instance.chartData,
    };
