// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chart_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChartPoint _$ChartPointFromJson(Map<String, dynamic> json) => ChartPoint(
      label: json['label'] as String,
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
    );

Map<String, dynamic> _$ChartPointToJson(ChartPoint instance) =>
    <String, dynamic>{
      'label': instance.label,
      'income': instance.income,
      'expense': instance.expense,
    };
