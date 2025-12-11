import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../settings/model/currency_formatter.dart';
import '../models/analytics_summary.dart';

const double _kPadding = 16.0;
const double _kSpacing = 8.0;

class AverageExpenseCard extends StatelessWidget {
  final AnalyticsSummary summary;

  const AverageExpenseCard({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_kPadding),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.savings,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: _kSpacing * 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Чистый доход',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Изменение дохода: ${summary.incomeChange.toStringAsFixed(1)}%, '
                        'расхода: ${summary.expenseChange.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(summary.netIncome, context),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
