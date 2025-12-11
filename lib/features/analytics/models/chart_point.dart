import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chart_point.g.dart';

@JsonSerializable()
class ChartPoint extends Equatable {
  final String label;
  final double income;
  final double expense;

  const ChartPoint({
    required this.label,
    required this.income,
    required this.expense,
  });

  factory ChartPoint.fromJson(Map<String, dynamic> json) => _$ChartPointFromJson(json);
  Map<String, dynamic> toJson() => _$ChartPointToJson(this);

  @override
  List<Object?> get props => [label, income, expense];
}
