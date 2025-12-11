import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/chart_point.dart';
import '../models/period_type.dart';

const double _kPadding = 16.0;
const double _kSpacing = 8.0;

class AnalyticsChart extends StatelessWidget {
  final List<ChartPoint> chartData;
  final PeriodType selectedPeriod;
  final DateTime selectedDate;
  final double totalAmount;

  static const double minBarWidth = 36; // Минимальная ширина одного бара
  static const double groupsSpace = 12; // Промежуток между группами
  static const double horizontalPadding = 32; // Паддинги внутри

  const AnalyticsChart({
    super.key,
    required this.chartData,
    required this.selectedPeriod,
    required this.selectedDate,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Padding(
          padding: const EdgeInsets.all(_kPadding),
          child: Center(
            child: Text(
              'Нет данных для отображения.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    // ширина = баров * minBarWidth + промежутков + паддинги
    final chartWidth = chartData.length * minBarWidth +
        (chartData.length - 1) * groupsSpace +
        horizontalPadding * 2;

    final maxY = _getMaxY(chartData);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(_kPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: _kSpacing * 2),
            SizedBox(
              height: 260,
              // === ГОРИЗОНТАЛЬНЫЙ СКРОЛЛ ===
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: chartWidth,
                  child: BarChart(
                    BarChartData(
                      barGroups: _buildBarGroups(chartData),
                      groupsSpace: groupsSpace,
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: maxY / 5,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.15),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                            interval: maxY / 5,
                            getTitlesWidget: (value, meta) =>
                                _BarAxisLabel(value: value),
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value < 0 || value >= chartData.length) return const SizedBox();
                              return _BarBottomLabel(
                                label: _formatLabel(chartData[value.toInt()].label, selectedPeriod),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 600),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          'Динамика доходов и расходов',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          _formatPeriodLabel(selectedDate, selectedPeriod),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<ChartPoint> points) {
    return points.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return BarChartGroupData(
        x: index,
        barsSpace: 6,
        barRods: [
          BarChartRodData(
            toY: data.income.toDouble(),
            color: Colors.greenAccent.shade400,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 0,
              color: Colors.transparent,
            ),
          ),
          BarChartRodData(
            toY: data.expense.toDouble(),
            color: Colors.redAccent.shade200,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 0,
              color: Colors.transparent,
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY(List<ChartPoint> data) {
    final maxIncome = data.map((e) => e.income).reduce((a, b) => a > b ? a : b);
    final maxExpense = data.map((e) => e.expense).reduce((a, b) => a > b ? a : b);
    final maxY = [maxIncome, maxExpense].reduce((a, b) => a > b ? a : b);
    return (maxY * 1.2).clamp(1000, double.infinity);
  }

  String _formatLabel(String label, PeriodType period) {
    switch (period) {
      case PeriodType.DAY:
        return label;
      case PeriodType.WEEK:
        return {
          'monday': 'Пн',
          'tuesday': 'Вт',
          'wednesday': 'Ср',
          'thursday': 'Чт',
          'friday': 'Пт',
          'saturday': 'Сб',
          'sunday': 'Вс',
          'mon': 'Пн',
          'tue': 'Вт',
          'wed': 'Ср',
          'thu': 'Чт',
          'fri': 'Пт',
          'sat': 'Сб',
          'sun': 'Вс',
        }[label.toLowerCase()] ?? label;
      case PeriodType.MONTH:
        final date = DateTime.tryParse(label);
        return date != null ? '${date.day}' : label;
      case PeriodType.YEAR:
        return {
          'jan': 'Янв', 'feb': 'Фев', 'mar': 'Мар', 'apr': 'Апр',
          'may': 'Май', 'jun': 'Июн', 'jul': 'Июл', 'aug': 'Авг',
          'sep': 'Сен', 'oct': 'Окт', 'nov': 'Ноя', 'dec': 'Дек',
        }[label.toLowerCase()] ?? label;
    }
  }

  String _formatPeriodLabel(DateTime date, PeriodType type) {
    switch (type) {
      case PeriodType.WEEK:
      case PeriodType.DAY:
        return '${date.day}.${date.month}.${date.year}';
      case PeriodType.MONTH:
        return '${date.month}.${date.year}';
      case PeriodType.YEAR:
        return '${date.year}';
    }
  }
}

class _BarAxisLabel extends StatelessWidget {
  final double value;

  const _BarAxisLabel({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == 0) return const SizedBox();
    String formatted;
    if (value >= 1e6) {
      formatted = '${(value / 1e6).toStringAsFixed(1)} млн';
    } else if (value >= 1e3) {
      formatted = '${(value / 1e3).toStringAsFixed(0)} тыс';
    } else {
      formatted = value.toStringAsFixed(0);
    }
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        '$formatted ₸',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _BarBottomLabel extends StatelessWidget {
  final String label;

  const _BarBottomLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
