import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../blocs/analytics_bloc.dart';
import '../blocs/analytics_event.dart';
import '../blocs/analytics_state.dart';
import '../models/analytics_summary.dart';

import '../models/period_type.dart';
import '../../settings/model/currency_formatter.dart';
import '../models/analytics_categories.dart';

const double _kPadding = 16.0;
const double _kSpacing = 8.0;

class CategoryChartScreen extends StatefulWidget {
  final AnalyticsSummary summary;
  final DateTime selectedDate;
  final PeriodType selectedPeriod;

  const CategoryChartScreen({
    Key? key,
    required this.summary,
    required this.selectedDate,
    required this.selectedPeriod,
  }) : super(key: key);

  @override
  State<CategoryChartScreen> createState() => _CategoryChartScreenState();
}

class _CategoryChartScreenState extends State<CategoryChartScreen> {
  late DateTime selectedDate;
  late PeriodType selectedPeriod;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    selectedPeriod = widget.selectedPeriod;
    _loadData();
  }

  void _loadData() {
    context.read<AnalyticsBloc>().add(
      LoadAnalyticsCategories(
        periodType: selectedPeriod,
        year: selectedDate.year,
        month: selectedPeriod != PeriodType.YEAR ? selectedDate.month : null,
        day: selectedPeriod == PeriodType.DAY ? selectedDate.day : null,
        lang: "ru",
      ),
    );
  }

  void _onPeriodChanged(PeriodType type) {
    setState(() {
      selectedPeriod = type;
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика по категориям'),
      ),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(_kPadding),
            child: Padding(
              padding: EdgeInsets.all(_kPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPeriodButton(PeriodType.WEEK, 'Неделя'),
                  _buildPeriodButton(PeriodType.MONTH, 'Месяц'),
                  _buildPeriodButton(PeriodType.YEAR, 'Год'),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (context, state) {
                if (state is AnalyticsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AnalyticsCategoriesLoaded) {
                  return _buildContent(state.categories);
                }
                if (state is AnalyticsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 48, color: Theme.of(context).colorScheme.error),
                        SizedBox(height: _kSpacing),
                        Text(
                          'Ошибка загрузки данных',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        SizedBox(height: _kSpacing),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: _kSpacing * 2),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: Icon(Icons.refresh),
                          label: Text('Повторить'),
                        )
                      ],
                    ),
                  );
                }

                return Center(
                  child: Text('Нет данных для отображения.'),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPeriodButton(PeriodType type, String label) {
    final isSelected = selectedPeriod == type;
    return FilledButton(
      onPressed: () => _onPeriodChanged(type),
      style: FilledButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceVariant,
        foregroundColor: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: Text(label),
    );
  }

  Widget _buildContent(AnalyticsCategories categories) {
    final allCategories = [
      ...categories.income.map((e) => {
        'name': e.categoryName,
        'amount': e.amount,
        'type': 'income',
      }),
      ...categories.expense.map((e) => {
        'name': e.categoryName,
        'amount': e.amount,
        'type': 'expense',
      }),
    ];

    if (allCategories.isEmpty) {
      return Center(
        child: Text('Нет данных за выбранный период.'),
      );
    }

    final maxAmount = allCategories.fold<double>(
      0.0,
          (max, cat) {
        final amount = (cat['amount'] as num?)?.toDouble() ?? 0.0;
        return amount > max ? amount : max;
      },
    );

    final interval = maxAmount > 0 ? maxAmount / 5 : 1.0;

    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            margin: EdgeInsets.all(_kPadding),
            child: Padding(
              padding: EdgeInsets.all(_kPadding),
              child: SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxAmount * 1.2,
                    barGroups: allCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final cat = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: (cat['amount'] as num?)?.toDouble() ?? 0.0,
                            color: cat['type'] == 'income'
                                ? Colors.green
                                : Colors.red,
                            width: 16,
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= allCategories.length) {
                              return SizedBox();
                            }
                            final cat = allCategories[value.toInt()];
                            return Text(
                              cat['name'] as String,
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              _formatLargeNumber(value),
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.shade300,
                        dashArray: [5, 5],
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: _kSpacing),
          Card(
            margin: EdgeInsets.all(_kPadding),
            child: Column(
              children: allCategories.map((cat) {
                final color =
                cat['type'] == 'income' ? Colors.green : Colors.red;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(
                      cat['type'] == 'income'
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: color,
                    ),
                  ),
                  title: Text(cat['name'] as String),
                  trailing: Text(
                    CurrencyFormatter.format((cat['amount'] as num?)?.toDouble() ?? 0.0, context),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                  // НЕ ДЕЛАЙ onTap, просто смотри как read-only список!
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  String _formatLargeNumber(double value) {
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(1)}B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}K';
    return value.toStringAsFixed(1);
  }
}
