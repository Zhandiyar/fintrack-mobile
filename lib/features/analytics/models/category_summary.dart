  import 'package:equatable/equatable.dart';
  import 'package:json_annotation/json_annotation.dart';

  part 'category_summary.g.dart';

  @JsonSerializable()
  class CategorySummary extends Equatable {
    final int categoryId;
    final String categoryName;
    final String icon;
    final String color;
    final double amount;
    final double percent;

    factory CategorySummary.fromJson(Map<String, dynamic> json) =>
        _$CategorySummaryFromJson(json);

  CategorySummary(this.categoryId, this.categoryName, this.icon, this.color, this.amount, this.percent);

    Map<String, dynamic> toJson() => _$CategorySummaryToJson(this);

    @override
    List<Object?> get props =>
        [categoryId, categoryName, icon, color, amount, percent];
  }
