// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../blocs/analytics_bloc.dart';
// import '../blocs/analytics_event.dart';
// import '../blocs/analytics_state.dart';
// import '../models/analytics_category.dart';
// import '../models/period_type.dart';
//
// const double _kPadding = 16.0;
// const double _kSpacing = 8.0;
//
// class CategoryAnalyticsScreen extends StatefulWidget {
//   final String categoryName;
//   final PeriodType periodType;
//   final DateTime selectedDate;
//   final String lang;
//
//   const CategoryAnalyticsScreen({
//     super.key,
//     required this.categoryName,
//     required this.periodType,
//     required this.selectedDate,
//     required this.lang,
//   });
//
//   @override
//   State<CategoryAnalyticsScreen> createState() => _CategoryAnalyticsScreenState();
// }
//
// class _CategoryAnalyticsScreenState extends State<CategoryAnalyticsScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }
//
//   void _loadData() {
//     context.read<AnalyticsBloc>().add(
//       LoadAnalyticsCategoryDetails(
//         categoryName: widget.categoryName,
//         periodType: widget.periodType,
//         year: widget.selectedDate.year,
//         month: widget.periodType != PeriodType.YEAR ? widget.selectedDate.month : null,
//         day: widget.periodType == PeriodType.DAY ? widget.selectedDate.day : null,
//         lang: widget.lang,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Категория: ${widget.categoryName}'),
//       ),
//       body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
//         builder: (context, state) {
//           if (state is AnalyticsLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (state is AnalyticsCategoryDetailsLoaded) {
//             return _buildContent(state.category);
//           }
//           if (state is AnalyticsError) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.error, size: 48, color: Theme.of(context).colorScheme.error),
//                   const SizedBox(height: _kSpacing),
//                   Text(
//                     'Ошибка загрузки данных',
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       color: Theme.of(context).colorScheme.error,
//                     ),
//                   ),
//                   const SizedBox(height: _kSpacing),
//                   Text(state.message),
//                   const SizedBox(height: _kSpacing * 2),
//                   ElevatedButton.icon(
//                     onPressed: _loadData,
//                     icon: const Icon(Icons.refresh),
//                     label: const Text('Повторить'),
//                   ),
//                 ],
//               ),
//             );
//           }
//
//           return const Center(
//             child: Text('Нет данных для отображения'),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildContent(AnalyticsCategory category) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(_kPadding),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             category.categoryName,
//             style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: _kSpacing),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildStatCard(
//                   title: 'Доход',
//                   value: '${category.totalIncome.toStringAsFixed(2)} ₸',
//                   color: Colors.green,
//                 ),
//               ),
//               const SizedBox(width: _kSpacing),
//               Expanded(
//                 child: _buildStatCard(
//                   title: 'Расход',
//                   value: '${category.totalExpense.toStringAsFixed(2)} ₸',
//                   color: Colors.red,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: _kSpacing * 2),
//           if (category.chartData.isNotEmpty) ...[
//             Text(
//               'Данные по периодам:',
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//             const SizedBox(height: _kSpacing),
//             ...category.chartData.map(
//                   (point) => ListTile(
//                 title: Text(point.label),
//                 subtitle: Text('Доход: ${point.income.toStringAsFixed(2)} ₸, '
//                     'Расход: ${point.expense.toStringAsFixed(2)} ₸'),
//               ),
//             ),
//           ] else
//             const Text('Нет данных по графику.'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatCard({
//     required String title,
//     required String value,
//     required Color color,
//   }) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(_kPadding),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title, style: Theme.of(context).textTheme.bodyMedium),
//             const SizedBox(height: _kSpacing),
//             Text(
//               value,
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 color: color,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
