
import 'transaction_type.dart';

class TransactionRequestDto {
  final int? id;
  final double amount;
  final DateTime date;
  final String? comment;
  final TransactionType type;
  final int categoryId;
  final String lang;

  TransactionRequestDto({
    this.id,
    required this.amount,
    required this.date,
    this.comment,
    required this.type,
    required this.categoryId,
    required this.lang
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'comment': comment,
    'type': transactionTypeToString(type),
    'categoryId': categoryId,
    'lang': lang
  };
}
