  import 'package:equatable/equatable.dart';
  import 'package:json_annotation/json_annotation.dart';

  import 'chart_point.dart';

  part 'analytics_summary.g.dart';

  @JsonSerializable()
  class AnalyticsSummary extends Equatable {
    final double currentIncome;
    final double currentExpense;
    final double netIncome;
    final double incomeChange;
    final double expenseChange;
    final List<ChartPoint> chartData;

    const AnalyticsSummary({
      required this.currentIncome,
      required this.currentExpense,
      required this.netIncome,
      required this.incomeChange,
      required this.expenseChange,
      required this.chartData,
    });

    factory AnalyticsSummary.fromJson(Map<String, dynamic> json) =>
        _$AnalyticsSummaryFromJson(json);

    Map<String, dynamic> toJson() => _$AnalyticsSummaryToJson(this);

    @override
    List<Object?> get props => [
      currentIncome,
      currentExpense,
      netIncome,
      incomeChange,
      expenseChange,
      chartData,
    ];
  }
