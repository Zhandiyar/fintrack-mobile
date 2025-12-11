import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../settings/model/currency_formatter.dart';
import '../../category/models/transaction_category.dart';
import '../models/analytics_categories.dart';

const List<Color> pieColors = [
  Color(0xFF90CAF9), // soft blue
  Color(0xFFA5D6A7), // soft green
  Color(0xFFFFCC80), // soft orange
  Color(0xFFFFAB91), // soft red
  Color(0xFFCE93D8), // soft purple
  Color(0xFF80CBC4), // soft teal
];

const double _pieChartHeight = 140;
const double _pieChartCenterSpace = 44;
const double _pieChartRadius = 46;
const double _pieChartRadiusSelected = 56;
const double _pieChartSectionSpace = 2;
const double _pieChartTitleOffset = .77;
const double _pieChartMinPercentToShowLabel = 3.0;
const double _pieChartOffsetFromSwitcher = 20.0;
const double _categoryIconRadius = 13;
const int _maxCategoriesToShow = 5;

class AnalyticsPieDashboard extends StatefulWidget {
  final AnalyticsCategories categories;
  final bool isExpense;
  final void Function(int? categoryId, String categoryName, bool isExpense)
      onCategoryTap;

  const AnalyticsPieDashboard({
    Key? key,
    required this.categories,
    required this.onCategoryTap,
    this.isExpense = true,
  }) : super(key: key);

  @override
  State<AnalyticsPieDashboard> createState() => _AnalyticsPieDashboardState();
}

class _AnalyticsPieDashboardState extends State<AnalyticsPieDashboard> {
  int touchedIndex = -1;
  bool showExpense = true;

  @override
  void initState() {
    super.initState();
    showExpense = widget.isExpense;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesList =
        showExpense ? widget.categories.expense : widget.categories.income;
    final total = showExpense
        ? widget.categories.totalExpense
        : widget.categories.totalIncome;
    final showCount = categoriesList.length > _maxCategoriesToShow
        ? _maxCategoriesToShow
        : categoriesList.length;

    final hasData =
        categoriesList.isNotEmpty && categoriesList.any((c) => c.amount > 0);

    final selected = touchedIndex >= 0 && touchedIndex < categoriesList.length
        ? categoriesList[touchedIndex]
        : null;

    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text("Расходы"),
              selected: showExpense,
              onSelected: (val) => setState(() {
                showExpense = true;
                touchedIndex = -1;
              }),
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text("Доходы"),
              selected: !showExpense,
              onSelected: (val) => setState(() {
                showExpense = false;
                touchedIndex = -1;
              }),
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: _pieChartOffsetFromSwitcher),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: hasData
                      ? GestureDetector(
                          onTap: () {
                            setState(() => touchedIndex = -1);
                          },
                          child: SizedBox(
                            height: _pieChartHeight,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: _pieChartCenterSpace,
                                sectionsSpace: _pieChartSectionSpace,
                                startDegreeOffset: -90,
                                sections: List.generate(showCount, (i) {
                                  final cat = categoriesList[i];
                                  final color = pieColors[i % pieColors.length];
                                  final showTitle = cat.percent >=
                                      _pieChartMinPercentToShowLabel;
                                  return PieChartSectionData(
                                    value: cat.amount,
                                    color: color,
                                    radius: touchedIndex == i
                                        ? _pieChartRadiusSelected
                                        : _pieChartRadius,
                                    showTitle: showTitle,
                                    title: showTitle
                                        ? '${cat.percent.toStringAsFixed(1)}%'
                                        : '',
                                    titlePositionPercentageOffset:
                                        _pieChartTitleOffset,
                                    titleStyle: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _bestContrastColor(color),
                                      shadows: [
                                        Shadow(
                                          blurRadius: 2,
                                          color: Colors.black.withOpacity(0.15),
                                        )
                                      ],
                                    ),
                                  );
                                }),
                                pieTouchData: PieTouchData(
                                  touchCallback: hasData
                                      ? (event, response) {
                                          final idx = response?.touchedSection
                                              ?.touchedSectionIndex;
                                          setState(() {
                                            touchedIndex = idx == null
                                                ? touchedIndex
                                                : (touchedIndex == idx
                                                    ? -1
                                                    : idx);
                                          });
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pie_chart_outline,
                                  size: 54, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                'Нет данных',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: Colors.grey[400],
                                        fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: selected == null
                      ? () {
                    widget.onCategoryTap(
                      null,
                      showExpense ? "Все расходы" : "Все доходы",
                      showExpense,
                    );
                  }
                      : () {
                    // Если выбран сектор — переход к выбранной категории!
                    widget.onCategoryTap(
                      selected.categoryId,
                      selected.categoryName,
                      showExpense,
                    );
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected?.categoryName ??
                                (showExpense ? "Все расходы" : "Все доходы"),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatter.format(
                                selected?.amount ?? total, context),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: hasData
                      ? Column(
                          children: List.generate(showCount, (i) {
                            final cat = categoriesList[i];
                            final color = pieColors[i % pieColors.length];
                            final selectedCat = touchedIndex == i;
                            return GestureDetector(
                              onTap: () {
                                widget.onCategoryTap(
                                  cat.categoryId,
                                  cat.categoryName,
                                  showExpense,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedCat
                                      ? color.withOpacity(0.10)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 2),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: color,
                                      radius: _categoryIconRadius,
                                      child: Icon(
                                        _iconFromString(cat.icon),
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        cat.categoryName,
                                        style: const TextStyle(fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(
                                          cat.amount, context),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      "${cat.percent.toStringAsFixed(1)}%",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        )
                      : const SizedBox(),
                ),
                if (hasData && categoriesList.length > _maxCategoriesToShow)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "+ ещё ${categoriesList.length - _maxCategoriesToShow} категорий",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _bestContrastColor(Color bgColor) {
    return ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  IconData _iconFromString(String icon) {
    return iconMap[icon] ?? Icons.category;
  }
}
