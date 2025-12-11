import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../analytics/models/period_type.dart';
import '../../category/models/transaction_category.dart';
import '../blocs/transaction_bloc.dart';
import '../blocs/transaction_event.dart';
import '../blocs/transaction_state.dart';
import '../models/transaction_type.dart';
import '../../settings/model/currency_formatter.dart';
import '../screens/transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final int? categoryId;
  final String categoryName;
  final bool isExpense;
  final PeriodType periodType;
  final DateTime selectedDate;

  const TransactionsScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
    required this.isExpense,
    required this.periodType,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late TransactionBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = TransactionBloc(context.read())
      ..add(_buildLoadEvent());
  }

  // Для обновления фильтров (универсально, не дублируй код)
  LoadTransactions _buildLoadEvent() {
    return LoadTransactions(
      type: widget.isExpense ? TransactionType.EXPENSE : TransactionType.INCOME,
      categoryId: widget.categoryId,
      periodType: widget.periodType,
      year: widget.selectedDate.year,
      month: widget.periodType != PeriodType.YEAR ? widget.selectedDate.month : null,
      day: widget.periodType == PeriodType.DAY ? widget.selectedDate.day : null,
    );
  }

  String _formatPeriod() {
    switch (widget.periodType) {
      case PeriodType.YEAR:
        return '${widget.selectedDate.year} год';
      case PeriodType.MONTH:
        return '${_monthName(widget.selectedDate.month)} ${widget.selectedDate.year}';
      case PeriodType.WEEK:
        return 'Неделя ${_weekOfYear(widget.selectedDate)} • ${widget.selectedDate.year}';
      case PeriodType.DAY:
        return '${widget.selectedDate.day.toString().padLeft(2, '0')}.${widget.selectedDate.month.toString().padLeft(2, '0')}.${widget.selectedDate.year}';
      default:
        return '';
    }
  }

  String _monthName(int month) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[month - 1];
  }

  int _weekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    return ((date.difference(firstDayOfYear).inDays + firstDayOfYear.weekday) / 7).ceil();
  }

  IconData _iconFromString(String iconName) {
    return iconMap[iconName] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.categoryName),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Плашка с периодом
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    widget.isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: widget.isExpense ? Colors.redAccent : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatPeriod(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      _bloc.add(_buildLoadEvent());
                    },
                    child: Builder(
                      builder: (context) {
                        if (state is TransactionLoading) {
                          return ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            itemCount: 6,
                            separatorBuilder: (context, i) => const Divider(height: 1),
                            itemBuilder: (context, i) => const _TransactionSkeleton(),
                          );
                        }
                        if (state is TransactionError) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              Icon(Icons.error, size: 48, color: Colors.redAccent),
                              const SizedBox(height: 8),
                              Text(
                                state.message,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () => _bloc.add(_buildLoadEvent()),
                                  child: const Text('Повторить'),
                                ),
                              )
                            ],
                          );
                        }
                        if (state is TransactionLoaded) {
                          final transactions = state.transactions;
                          if (transactions.isEmpty) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 80),
                                Center(child: Text('Нет транзакций по этой категории.', style: TextStyle(fontSize: 16))),
                              ],
                            );
                          }
                          return ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            itemCount: transactions.length,
                            separatorBuilder: (context, i) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final tx = transactions[i];
                              final color = Color(int.parse(
                                tx.category.color.replaceAll('#', '0xff'),
                              ));
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: color,
                                  child: Icon(
                                    _iconFromString(tx.category.icon),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  tx.comment?.isNotEmpty == true
                                      ? tx.comment!
                                      : (tx.category.name ?? '-'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${tx.date.day.toString().padLeft(2, '0')}.${tx.date.month.toString().padLeft(2, '0')}.${tx.date.year}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                trailing: Text(
                                  CurrencyFormatter.format(tx.amount, context),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: widget.isExpense ? Colors.redAccent : Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TransactionDetailScreen(transaction: tx),
                                    ),
                                  );
                                  // Если на detail был апдейт или удаление — обновляем список
                                  if (result == true) {
                                    _bloc.add(_buildLoadEvent());
                                  }
                                },
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Простая shimmer заглушка для лоадинга
class _TransactionSkeleton extends StatelessWidget {
  const _TransactionSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _ShimmerCircle(size: 38),
      title: _ShimmerRect(width: double.infinity, height: 16),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: _ShimmerRect(width: 60, height: 12),
      ),
      trailing: _ShimmerRect(width: 60, height: 18),
    );
  }
}

class _ShimmerRect extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerRect({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  final double size;

  const _ShimmerCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}
