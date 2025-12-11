import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../category/blocs/category_bloc.dart';
import '../../category/blocs/category_event.dart';
import '../../category/blocs/category_state.dart';
import '../../category/models/transaction_category.dart';
import '../../dashboard/notifiers/dashboard_refresh_notifier.dart';
import '../blocs/transaction_bloc.dart';
import '../blocs/transaction_event.dart';
import '../blocs/transaction_state.dart';
import '../models/transaction_response.dart';
import '../models/transaction_type.dart';
import '../../analytics/models/period_type.dart'; // для periodType
import 'transaction_detail_screen.dart';
import 'transaction_form_screen.dart';

// Если iconMap объявлен где-то глобально — оставь как есть
IconData _iconFromString(String icon) => iconMap[icon] ?? Icons.category;

Color hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({Key? key}) : super(key: key);

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  // ── локальное состояние фильтров ─────────────────────────────────────────────
  TransactionType? _type; // null = все
  int? _categoryId;
  PeriodType? _periodType; // быстрые пресеты: MONTH/WEEK/DAY
  int? _year;
  int? _month;
  int? _day;

  // произвольный диапазон
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // пагинацию можно добавить позже (page/size)
  final _page = 0;
  final _size = 50;

  @override
  void initState() {
    super.initState();
    // по умолчанию: текущий месяц
    final now = DateTime.now();
    _periodType = PeriodType.MONTH;
    _year = now.year;
    _month = now.month;
    _load();
  }

  Future<void> _load() async {
    context.read<TransactionBloc>().add(LoadTransactions(
      type: _type,
      categoryId: _categoryId,
      periodType: _periodType,
      year: _year,
      month: _month,
      day: _day,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      page: _page,
      size: _size,
    ));
  }

  Future<void> _reload() => _load();

  // ── обработчики фильтров ────────────────────────────────────────────────────
  void _setQuickPeriod(PeriodType? pt) {
    final now = DateTime.now();
    setState(() {
      _periodType = pt;
      _dateFrom = null;
      _dateTo = null;
      if (pt == PeriodType.MONTH) {
        _year = now.year;
        _month = now.month;
        _day = null;
      } else if (pt == PeriodType.WEEK) {
        // Неделя: просто используем кастомный диапазон за последние 7 дней
        _periodType = null;
        final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final from = to.subtract(const Duration(days: 6));
        _dateFrom = from;
        _dateTo = to;
      } else if (pt == PeriodType.DAY) {
        _year = now.year;
        _month = now.month;
        _day = now.day;
      }
    });
    _load();
  }

  void _setType(TransactionType? t) {
    setState(() => _type = t);
    _load();
  }

  void _setCategory(int? id) {
    setState(() => _categoryId = id);
    _load();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialFrom = _dateFrom ?? DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final initialTo = _dateTo ?? now;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(start: initialFrom, end: initialTo),
      locale: const Locale('ru'),
    );
    if (range != null) {
      setState(() {
        _periodType = null; // чтобы не конфликтовало
        _year = _month = _day = null;
        _dateFrom = DateTime(range.start.year, range.start.month, range.start.day, 0, 0, 0);
        _dateTo   = DateTime(range.end.year,   range.end.month,   range.end.day,   23, 59, 59);
      });
      _load();
    }
  }

  void _resetFilters() {
    final now = DateTime.now();
    setState(() {
      _type = null;
      _categoryId = null;
      _periodType = PeriodType.MONTH;
      _year = now.year;
      _month = now.month;
      _day = null;
      _dateFrom = null;
      _dateTo = null;
    });
    _load();
  }

  // ── UI ───────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dateRangeLabel = (_dateFrom != null && _dateTo != null)
        ? '${DateFormat('d MMM', 'ru').format(_dateFrom!)} — ${DateFormat('d MMM', 'ru').format(_dateTo!)}'
        : 'Диапазон';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Транзакции'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload, tooltip: 'Обновить'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<TransactionResponseDto?>(
            MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
          );
          if (!mounted) return;
          if (created != null) {
            context.read<TransactionBloc>().add(UpsertTransactionFromServer(created));
            dashboardRefreshNotifier.value = true;
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ── панель фильтров ─────────────────────────────────────────────────
          _FiltersBar(
            type: _type,
            onTypeChanged: _setType,
            periodType: _periodType,
            onQuickPeriod: _setQuickPeriod,
            customRangeLabel: dateRangeLabel,
            onPickRange: _pickCustomRange,
            onReset: _resetFilters,
            onPickCategory: () async {
              final id = await showModalBottomSheet<int?>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const _CategoryPickerSheet(),
              );
              if (id is int? /* null тоже ок */) _setCategory(id);
            },
            selectedCategoryId: _categoryId,
          ),

          const Divider(height: 1),

          // ── список ─────────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TransactionError) {
                  return Center(child: Text('Ошибка: ${state.message}'));
                }
                if (state is! TransactionLoaded || state.transactions.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Нет транзакций')),
                      ],
                    ),
                  );
                }

                final grouped = _groupByDate(state.transactions);
                final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      final items = grouped[date]!..sort((a, b) => b.date.compareTo(a.date));
                      final total = items.fold<double>(0, (sum, tx) => sum + tx.amount);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateHeader(context, date, total),
                          ...items.map((tx) => _TxCard(
                            tx: tx,
                            onTap: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionDetailScreen(transaction: tx),
                                ),
                              );
                              if (updated == true && mounted) {
                                // блок уже апсертит, но при желании можно _reload();
                              }
                            },
                          )),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<TransactionResponseDto>> _groupByDate(List<TransactionResponseDto> list) {
    return list.fold(<DateTime, List<TransactionResponseDto>>{}, (map, tx) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      (map[key] ??= []).add(tx);
      return map;
    });
  }

  Widget _buildDateHeader(BuildContext context, DateTime date, double total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat('d MMMM y', 'ru').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${total.toStringAsFixed(2)} ₸',
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final TransactionResponseDto tx;
  final VoidCallback onTap;

  const _TxCard({required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.type == TransactionType.EXPENSE;
    final color = hexToColor(tx.category.color);
    final icon = _iconFromString(tx.category.icon);
    final sign = isExpense ? '-' : '+';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.16),
          child: Icon(icon, color: color),
        ),
        title: Text(tx.category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(DateFormat('HH:mm').format(tx.date),
            style: Theme.of(context).textTheme.bodySmall),
        trailing: Text(
          '$sign${tx.amount.toStringAsFixed(2)} ₸',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        onTap: onTap,
      ),
    );
  }
}

// ───────────────────────── Панель фильтров ─────────────────────────

class _FiltersBar extends StatelessWidget {
  final TransactionType? type;
  final void Function(TransactionType?) onTypeChanged;

  final PeriodType? periodType; // для пресетов DAY/WEEK/MONTH
  final void Function(PeriodType?) onQuickPeriod;

  final String customRangeLabel;
  final VoidCallback onPickRange;

  final VoidCallback onReset;

  final VoidCallback onPickCategory;
  final int? selectedCategoryId;

  const _FiltersBar({
    required this.type,
    required this.onTypeChanged,
    required this.periodType,
    required this.onQuickPeriod,
    required this.customRangeLabel,
    required this.onPickRange,
    required this.onReset,
    required this.onPickCategory,
    required this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = type == TransactionType.INCOME;
    final isExpense = type == TransactionType.EXPENSE;

    return SizedBox(
      height: 112,
      child: Column(
        children: [
          // строка 1: типы + сброс
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                _Segment(
                  labels: const ['Все', 'Расходы', 'Доходы'],
                  selectedIndex: type == null ? 0 : (isExpense ? 1 : 2),
                  onChanged: (i) => onTypeChanged(
                    i == 0 ? null : (i == 1 ? TransactionType.EXPENSE : TransactionType.INCOME),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Сброс'),
                ),
              ],
            ),
          ),
          // строка 2: пресеты периодов + категория + кастомный диапазон
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  selected: periodType == PeriodType.DAY,
                  label: const Text('Сегодня'),
                  onSelected: (_) => onQuickPeriod(PeriodType.DAY),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: false, // неделя мы реализуем кастомным диапазоном
                  label: const Text('Неделя'),
                  onSelected: (_) => onQuickPeriod(PeriodType.WEEK),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: periodType == PeriodType.MONTH,
                  label: const Text('Месяц'),
                  onSelected: (_) => onQuickPeriod(PeriodType.MONTH),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onPickCategory,
                  icon: const Icon(Icons.category_outlined),
                  label: Text(selectedCategoryId == null ? 'Категория' : 'Категория: #$selectedCategoryId'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onPickRange,
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(customRangeLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _Segment({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: List.generate(labels.length, (i) => i == selectedIndex),
      onPressed: onChanged,
      borderRadius: BorderRadius.circular(10),
      children: labels.map((t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(t),
      )).toList(),
    );
  }
}

// ───────────────────────── BottomSheet выбора категории ─────────────────────────

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          if (state is CategoryLoading) {
            return const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()));
          }
          if (state is! CategoryLoaded) {
            // если категории ещё не грузились — инициируем
            context.read<CategoryBloc>().add(LoadCategories(TransactionType.EXPENSE));
            return const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()));
          }
          final categories = state.categories;

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Выберите категорию', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.clear),
                    title: const Text('Без фильтра по категории'),
                    onTap: () => Navigator.pop<int?>(context, null),
                  ),
                  const Divider(height: 0),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (_, i) {
                        final c = categories[i];
                        final color = c.colorValue;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(.15),
                            child: Icon(c.iconData, color: color),
                          ),
                          title: Text(c.displayName('ru')),
                          onTap: () => Navigator.pop<int?>(context, c.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
