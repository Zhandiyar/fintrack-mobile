import 'package:equatable/equatable.dart';
import '../../transaction/models/localized_transaction_response.dart';

class DashboardDto extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double currentPeriodIncome;
  final double currentPeriodExpense;
  final double incomeChange;
  final double expenseChange;
  final String periodLabel;
  final List<LocalizedTransactionResponseDto> recentTransactions;

  const DashboardDto({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.currentPeriodIncome,
    required this.currentPeriodExpense,
    required this.incomeChange,
    required this.expenseChange,
    required this.periodLabel,
    required this.recentTransactions,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) {
    return DashboardDto(
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpense: (json['totalExpense'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      currentPeriodIncome: (json['currentPeriodIncome'] as num).toDouble(),
      currentPeriodExpense: (json['currentPeriodExpense'] as num).toDouble(),
      incomeChange: (json['incomeChange'] as num).toDouble(),
      expenseChange: (json['expenseChange'] as num).toDouble(),
      periodLabel: json['periodLabel'],
      recentTransactions: (json['recentTransactions'] as List)
          .map((e) => LocalizedTransactionResponseDto.fromJson(e))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    totalIncome,
    totalExpense,
    balance,
    currentPeriodIncome,
    currentPeriodExpense,
    incomeChange,
    expenseChange,
    periodLabel,
    recentTransactions,
  ];
}
