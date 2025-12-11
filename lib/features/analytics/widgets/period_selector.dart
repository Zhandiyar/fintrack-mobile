import 'package:flutter/material.dart';

import '../models/period_type.dart';


const double _kPadding = 16.0;

class PeriodSelector extends StatelessWidget {
  final PeriodType selectedPeriod;
  final Function(PeriodType) onPeriodChanged;

  const PeriodSelector({
    Key? key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(_kPadding),
      child: Padding(
        padding: const EdgeInsets.all(_kPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPeriodButton(context, PeriodType.DAY, 'День'),
            _buildPeriodButton(context, PeriodType.WEEK, 'Неделя'),
            _buildPeriodButton(context, PeriodType.MONTH, 'Месяц'),
            _buildPeriodButton(context, PeriodType.YEAR, 'Год'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(BuildContext context, PeriodType type, String label) {
    final isSelected = selectedPeriod == type;
    return FilledButton(
      onPressed: () => onPeriodChanged(type),
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
} 