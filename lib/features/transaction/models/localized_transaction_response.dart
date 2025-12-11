

import 'package:equatable/equatable.dart';
import 'package:fintrack/features/transaction/models/transaction_category.dart';
import 'package:fintrack/features/transaction/models/transaction_type.dart' show TransactionType, transactionTypeFromString;


class LocalizedTransactionResponseDto extends Equatable {
  final int id;
  final double amount;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? comment;
  final TransactionType type;
  final TransactionCategoryDto category;

  LocalizedTransactionResponseDto({
    required this.id,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.comment,
    required this.type,
    required this.category
  });

  @override
  List<Object?> get props => [
    id,
    amount,
    date,
    createdAt,
    updatedAt,
    comment,
    type,
    category,
  ];

  factory LocalizedTransactionResponseDto.fromJson(Map<String, dynamic> json) =>
      LocalizedTransactionResponseDto(
        id: json['id'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        comment: json['comment'],
        type: transactionTypeFromString(json['type']),
        category: TransactionCategoryDto.fromJson(json['category']),
      );
}
