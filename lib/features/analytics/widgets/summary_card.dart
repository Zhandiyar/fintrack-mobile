// Вынеси эти классы лучше в отдельный файл ui/widgets/summary_card.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double netIncome;
  final double incomeChange;
  final double expenseChange;

  const SummaryCard({
    required this.income,
    required this.expense,
    required this.netIncome,
    required this.incomeChange,
    required this.expenseChange,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isNetPositive = netIncome >= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.south_west,
                    label: "Доходы",
                    value: income,
                    color: Colors.green.shade600,
                    change: incomeChange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.north_east,
                    label: "Расходы",
                    value: expense,
                    color: Colors.red.shade600,
                    change: expenseChange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _NetIncomeTile(net: netIncome),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final double change;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.change,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPositive = change >= 0;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.07),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            "${value.toStringAsFixed(2)} ₸",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive
                    ? Colors.green.shade500
                    : Colors.red.shade400,
                size: 16,
              ),
              const SizedBox(width: 3),
              Text(
                "${change.abs().toStringAsFixed(1)}%",
                style: TextStyle(
                  color: isPositive
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetIncomeTile extends StatelessWidget {
  final double net;

  const _NetIncomeTile({required this.net, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = net >= 0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.09)
            : Colors.red.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            "Чистый доход",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
                begin: 0, end: net), // анимация смены netIncome
            duration: const Duration(milliseconds: 600),
            builder: (context, value, _) => Text(
              "${value.toStringAsFixed(2)} ₸",
              style: TextStyle(
                color: isPositive
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
