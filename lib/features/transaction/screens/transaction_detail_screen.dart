import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../settings/model/currency_formatter.dart';
import '../../category/blocs/category_bloc.dart';
import '../../category/blocs/category_state.dart';
import '../../category/models/transaction_category.dart';
import '../../dashboard/notifiers/dashboard_refresh_notifier.dart';
import '../blocs/transaction_bloc.dart';
import '../blocs/transaction_event.dart';
import '../models/transaction_request.dart' show TransactionRequestDto;
import '../models/transaction_response.dart';
import '../models/transaction_type.dart';
import 'transaction_form_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionResponseDto transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TransactionResponseDto _transaction;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
  }

  TransactionCategory? _category(BuildContext ctx) {
    final st = ctx.read<CategoryBloc>().state;
    return st is CategoryLoaded
        ? st.categories.firstWhereOrNull((c) => c.id == _transaction.category.id)
        : null;
  }

  IconData _icon(BuildContext ctx) =>
      _category(ctx)?.iconData ??
          (_transaction.type == TransactionType.EXPENSE
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded);

  Color _color(BuildContext ctx) =>
      _category(ctx)?.colorValue ??
          (_transaction.type == TransactionType.EXPENSE ? Colors.red : Colors.green);

  Future<void> _edit(BuildContext ctx) async {
    final updated = await Navigator.push<TransactionResponseDto?>(
      ctx,
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          transaction: _transaction,
          type: _transaction.type,
        ),
      ),
    );

    if (updated != null && mounted) {
      // локально показываем то, что вернул сервер
      setState(() => _transaction = updated);

      // прокидываем апсерт в блок, чтобы список/дашборд обновились сразу
      ctx.read<TransactionBloc>().add(UpsertTransactionFromServer(updated));
      triggerDashboardRefresh();

      if (mounted) Navigator.pop(ctx, true); // вернёмся назад и сообщим, что были изменения
    }
  }

  Future<void> _confirmDelete(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text('Удалить транзакцию?'),
        content: const Text('Действие необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true && mounted) {
      ctx.read<TransactionBloc>().add(DeleteTransaction(_transaction.id));
      triggerDashboardRefresh();
      Navigator.pop(ctx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sign = _transaction.type == TransactionType.EXPENSE ? '-' : '+';
    final color = _color(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_transaction.type == TransactionType.INCOME ? 'Доход' : 'Расход'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
            tooltip: 'Удалить',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(.2),
                    child: Icon(_icon(context), color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        _transaction.displayCategoryName(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '$sign${CurrencyFormatter.format(_transaction.amount, context)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: color, fontWeight: FontWeight.bold),
                      ),
                    ]),
                  ),
                ]),
                const Divider(height: 32),
                _row('Дата', DateFormat('d MMMM y', 'ru_RU').format(_transaction.date)),
                const SizedBox(height: 8),
                _row('Время', DateFormat('HH:mm').format(_transaction.date)),
                if (_transaction.comment?.isNotEmpty ?? false) ...[
                  const Divider(height: 32),
                  _sectionTitle('Описание'),
                  const SizedBox(height: 8),
                  _commentBox(_transaction.comment!),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Редактировать'),
              onPressed: () => _edit(context),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _row(String label, String value) => Row(children: [
    SizedBox(
      width: 100,
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
    Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
  ]);

  Widget _sectionTitle(String text) => Row(children: [
    Icon(Icons.description_outlined,
        size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
    const SizedBox(width: 8),
    Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
  ]);

  Widget _commentBox(String comment) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.3),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(.3)),
    ),
    child: Text(comment, style: Theme.of(context).textTheme.bodyLarge),
  );
}

extension TransactionResponseDtoCopyWith on TransactionResponseDto {
  TransactionResponseDto copyWithRequest(TransactionRequestDto req) {
    return TransactionResponseDto(
      id: req.id ?? id,
      amount: req.amount,
      date: req.date,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      comment: req.comment,
      type: req.type,
      category: category, // при смене категории лучше использовать серверный ответ
    );
  }
}
