import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/analytics/screens/reports_screen.dart';
import '../../features/dashboard/blocs/dashboard_bloc.dart';
import '../../features/dashboard/blocs/dashboard_event.dart';
import '../../features/dashboard/notifiers/dashboard_refresh_notifier.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/transaction/screens/transaction_list_screen.dart';
import '../../features/settings/screens/SettingsScreen.dart';
import '../../features/transaction/screens/transaction_form_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionListScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  final PageStorageBucket _bucket = PageStorageBucket();

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageStorage(
        bucket: _bucket,
        child: _screens[_selectedIndex],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'main-fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
          );
          if (result == true) {
            // Вот тут вызывай triggerDashboardRefresh()
            triggerDashboardRefresh();
            // Можно ещё дополнительно дернуть context.read<DashboardBloc>().add(...)
            context.read<DashboardBloc>().add(LoadDashboard(
              year: DateTime.now().year,
              month: DateTime.now().month,
            ));
          }
        },
        elevation: 6,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Главная'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'История'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Отчёты'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Настройки'),
          ],
        ),
      ),
    );
  }
}
