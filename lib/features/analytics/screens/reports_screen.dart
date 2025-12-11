import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../transaction/screens/transactions_screen.dart';
import '../blocs/analytics_bloc.dart';
import '../blocs/analytics_event.dart';
import '../blocs/analytics_state.dart';
import '../models/analytics_summary.dart';
import '../models/period_type.dart';
import '../widgets/analytics_chart.dart';
import '../widgets/analytics_pie_dashboard.dart';
import '../widgets/period_selector.dart';
import '../widgets/date_selector.dart';
import '../widgets/summary_card.dart';

const double _kPadding = 16.0;
const double _kSpacing = 8.0;
const int _kStartYear = 2020;
const int _kEndYear = 2025;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime selectedDate = DateTime.now();
  PeriodType selectedPeriod = PeriodType.MONTH;
  String lang = 'ru';
  bool _categoriesRequested = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void _loadSummary() {
    context.read<AnalyticsBloc>().add(
      LoadAnalyticsSummary(
        periodType: selectedPeriod,
        year: selectedDate.year,
        month: selectedPeriod != PeriodType.YEAR ? selectedDate.month : null,
        day: selectedPeriod == PeriodType.DAY ? selectedDate.day : null,
      ),
    );
  }

  void _loadCategories() {
    context.read<AnalyticsBloc>().add(
      LoadAnalyticsCategories(
        periodType: selectedPeriod,
        year: selectedDate.year,
        month: selectedPeriod != PeriodType.YEAR ? selectedDate.month : null,
        day: selectedPeriod == PeriodType.DAY ? selectedDate.day : null,
        lang: lang,
      ),
    );
  }

  void _onPeriodChanged(PeriodType type) {
    setState(() {
      selectedPeriod = type;
      _categoriesRequested = false;
      _loadSummary();
    });
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      selectedDate = date;
      _categoriesRequested = false;
      _loadSummary();
    });
  }

  void _onCategoryTap(int? categoryId, String categoryName, bool isExpense) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionsScreen(
          categoryId: categoryId, // может быть null!
          categoryName: categoryName,
          isExpense: isExpense,
          periodType: selectedPeriod,
          selectedDate: selectedDate,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Отчеты по операциям')),
      body: Column(
        children: [
          PeriodSelector(
            selectedPeriod: selectedPeriod,
            onPeriodChanged: _onPeriodChanged,
          ),
          DateSelector(
            selectedDate: selectedDate,
            selectedPeriod: selectedPeriod,
            startYear: _kStartYear,
            endYear: _kEndYear,
            onDateChanged: _onDateChanged,
          ),
          Expanded(
            child: ListView(
              children: [
                BlocBuilder<AnalyticsBloc, AnalyticsState>(
                  buildWhen: (prev, curr) =>
                  curr is AnalyticsSummaryLoaded || curr is AnalyticsError,
                  builder: (context, state) {
                    if (state is AnalyticsSummaryLoaded) {
                      print('chartData: ${state.summary.chartData}');
                      // Запрос категорий только после успешной загрузки summary
                      if (!_categoriesRequested) {
                        _categoriesRequested = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
                      }
                      return _buildSummary(state.summary);
                    }
                    if (state is AnalyticsError) {
                      return _buildError(state.message);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                BlocBuilder<AnalyticsBloc, AnalyticsState>(
                  buildWhen: (prev, curr) =>
                  curr is AnalyticsCategoriesLoaded || curr is AnalyticsError,
                  builder: (context, state) {
                    if (state is AnalyticsCategoriesLoaded) {
                      return AnalyticsPieDashboard(
                        categories: state.categories,
                        onCategoryTap: (int? categoryId, String categoryName, bool isExpense) {
                          _onCategoryTap(categoryId, categoryName, isExpense);
                        },
                        isExpense: true, // или передавай из состояния
                      );
                    }
                    if (state is AnalyticsError) {
                      return _buildError(state.message);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(AnalyticsSummary summary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          SummaryCard(
            income: summary.currentIncome,
            expense: summary.currentExpense,
            netIncome: summary.netIncome,
            incomeChange: summary.incomeChange,
            expenseChange: summary.expenseChange,
          ),
          AnalyticsChart(
            chartData: summary.chartData,
            selectedPeriod: selectedPeriod,
            selectedDate: selectedDate,
            totalAmount: summary.currentIncome + summary.currentExpense,
          )
        ],
      ),
    );
  }


  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: _kSpacing),
          Text(
            'Ошибка загрузки данных',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: _kSpacing),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _kSpacing * 2),
          ElevatedButton.icon(
            onPressed: _loadSummary,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
