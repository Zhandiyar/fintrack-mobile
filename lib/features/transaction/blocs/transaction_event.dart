import 'package:equatable/equatable.dart';
import 'package:fintrack/features/transaction/models/transaction_request.dart';
import 'package:fintrack/features/transaction/models/transaction_type.dart';

import '../../analytics/models/period_type.dart';
import '../models/transaction_response.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final TransactionType? type;
  final int? categoryId;
  final PeriodType? periodType;
  final int? year;
  final int? month;
  final int? day;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int page;
  final int size;

  const LoadTransactions({
    this.type,
    this.categoryId,
    this.periodType,
    this.year,
    this.month,
    this.day,
    this.dateFrom,
    this.dateTo,
    this.page = 0,
    this.size = 20,
  });

  @override
  List<Object?> get props => [
        type,
        categoryId,
        periodType,
        year,
        month,
        day,
        dateFrom,
        dateTo,
        page,
        size
      ];
}

class AddTransaction extends TransactionEvent {
  final TransactionRequestDto transaction;

  const AddTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class UpdateTransaction extends TransactionEvent {
  final TransactionRequestDto transaction;

  const UpdateTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class UpsertTransactionFromServer extends TransactionEvent {
  final TransactionResponseDto tx;

  const UpsertTransactionFromServer(this.tx);

  @override
  List<Object?> get props => [tx];
}

class DeleteTransaction extends TransactionEvent {
  final int id;

  const DeleteTransaction(this.id);

  @override
  List<Object?> get props => [id];
}
