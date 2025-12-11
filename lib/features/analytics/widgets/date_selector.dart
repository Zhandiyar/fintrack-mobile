import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/period_type.dart';

const double _kPadding = 16.0;

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final PeriodType selectedPeriod;
  final int startYear;
  final int endYear;
  final Function(DateTime) onDateChanged;

  const DateSelector({
    Key? key,
    required this.selectedDate,
    required this.selectedPeriod,
    required this.startYear,
    required this.endYear,
    required this.onDateChanged,
  }) : super(key: key);

  String _formatDate() {
    switch (selectedPeriod) {
      case PeriodType.DAY:
        return DateFormat('d MMMM y', 'ru').format(selectedDate);
      case PeriodType.WEEK:
        return DateFormat('d MMMM y', 'ru').format(selectedDate);
      case PeriodType.MONTH:
        return DateFormat('MMMM y', 'ru').format(selectedDate);
      case PeriodType.YEAR:
        return DateFormat('y', 'ru').format(selectedDate);
    }
  }


  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDate = DateTime(startYear);
    final lastDate = DateTime(now.year + 1, 12, 31);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: _kPadding),
      child: Padding(
        padding: const EdgeInsets.all(_kPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.filled(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                DateTime newDate;
                switch (selectedPeriod) {
                  case PeriodType.WEEK:
                    newDate = selectedDate.subtract(const Duration(days: 7));
                    break;
                  case PeriodType.MONTH:
                    newDate = DateTime(
                      selectedDate.year,
                      selectedDate.month - 1,
                      1,
                    );
                    break;
                  case PeriodType.YEAR:
                    newDate = DateTime(selectedDate.year - 1);
                    break;
                  case PeriodType.DAY:
                    newDate = selectedDate.subtract(const Duration(days: 1));
                    break;
                }
                if (!newDate.isBefore(firstDate)) {
                  onDateChanged(newDate);
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  locale: const Locale('ru'),
                );
                if (date != null) {
                  onDateChanged(date);
                }
              },
              child: Text(
                _formatDate(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton.filled(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                DateTime newDate;
                switch (selectedPeriod) {
                  case PeriodType.WEEK:
                    newDate = selectedDate.add(const Duration(days: 7));
                    break;
                  case PeriodType.MONTH:
                    newDate = DateTime(
                      selectedDate.year,
                      selectedDate.month + 1,
                      1,
                    );
                    break;
                  case PeriodType.YEAR:
                    newDate = DateTime(selectedDate.year + 1);
                    break;
                  case PeriodType.DAY:
                    newDate = selectedDate.add(const Duration(days: 1));
                    break;
                }
                if (!newDate.isAfter(lastDate)) {
                  onDateChanged(newDate);
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 