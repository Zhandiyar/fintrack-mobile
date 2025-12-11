import 'package:equatable/equatable.dart';
import 'package:fintrack/features/transaction/models/transaction_response.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionResponseDto> transactions;

  const TransactionLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class TransactionSuccess extends TransactionState {
  final TransactionResponseDto tx;

  const TransactionSuccess(this.tx);

  @override
  List<Object?> get props => [tx];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}
