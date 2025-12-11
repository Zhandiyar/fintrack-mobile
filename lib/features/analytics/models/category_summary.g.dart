// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategorySummary _$CategorySummaryFromJson(Map<String, dynamic> json) =>
    CategorySummary(
      (json['categoryId'] as num).toInt(),
      json['categoryName'] as String,
      json['icon'] as String,
      json['color'] as String,
      (json['amount'] as num).toDouble(),
      (json['percent'] as num).toDouble(),
    );

Map<String, dynamic> _$CategorySummaryToJson(CategorySummary instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'icon': instance.icon,
      'color': instance.color,
      'amount': instance.amount,
      'percent': instance.percent,
    };
