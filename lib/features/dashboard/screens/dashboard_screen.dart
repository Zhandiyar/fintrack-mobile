import 'package:fintrack/features/dashboard/mapper/localized_tx_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../auth/blocs/auth_bloc.dart';
import '../../ai/screens/ai_analyze_card.dart';
import '../../auth/blocs/auth_event.dart';
import '../../auth/blocs/auth_state.dart';
import '../../category/models/transaction_category.dart';
import '../../iap/domain/model/entitlement_status.dart';
import '../../iap/domain/repository/iap_repository.dart';
import '../../iap/presentation/bloc/purchase_bloc.dart';
import '../../iap/presentation/bloc/purchase_event.dart';
import '../../iap/presentation/widgets/entitlement_guard.dart';
import '../../iap/presentation/widgets/premium_action.dart';
import '../../settings/blocs/currency/currency_bloc.dart';
import '../../transaction/screens/transaction_detail_screen.dart';
import '../blocs/dashboard_bloc.dart';
import '../blocs/dashboard_event.dart';
import '../blocs/dashboard_state.dart';
import '../../settings/model/currency_formatter.dart';
import '../../transaction/models/localized_transaction_response.dart';
import '../notifiers/dashboard_refresh_notifier.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum _QuickFilter { all, month, today }

class _DashboardScreenState extends State<DashboardScreen> {
  int _year = DateTime.now().year;
  int? _month = DateTime.now().month;
  int? _day;

  _QuickFilter _filter = _QuickFilter.month;

  @override
  void initState() {
    super.initState();
    _applyFilter(_filter, initial: true);
    dashboardRefreshNotifier.addListener(_onRefreshTick);
  }

  @override
  void dispose() {
    dashboardRefreshNotifier.removeListener(_onRefreshTick);
    super.dispose();
  }

  void _onRefreshTick() {
    if (!mounted) return;
    _reload();
    dashboardRefreshNotifier.value = false;
  }

  Future<void> _reload() async {
    context
        .read<DashboardBloc>()
        .add(LoadDashboard(year: _year, month: _month, day: _day));
  }

  // Реальные фильтры, поддерживаемые бэкендом
  void _applyFilter(_QuickFilter f, {bool initial = false}) {
    final now = DateTime.now();
    _filter = f;
    switch (f) {
      case _QuickFilter.all:
        _year = now.year;
        _month = null;
        _day = null;
        break;
      case _QuickFilter.month:
        _year = now.year;
        _month = now.month;
        _day = null;
        break;
      case _QuickFilter.today:
        _year = now.year;
        _month = now.month;
        _day = now.day;
        break;
    }
    if (!initial) setState(() {});
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.select((CurrencyBloc bloc) => bloc.state.currency);
    final authState = context.watch<AuthBloc>().state;

    final bool isAuthenticated = authState is AuthAuthenticated;
    final bool isGuest = authState is AuthAuthenticated && authState.isGuest;

    return MultiBlocListener(
      listeners: [
        BlocListener<PurchaseBloc, PurchaseState>(
          listenWhen: (prev, next) =>
              prev.status.isUnlocked != next.status.isUnlocked,
          listener: (context, s) {
            if (s.status.isUnlocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium активирован. Спасибо!')),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          elevation: 0.5,
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.background,
          title: const Text('Fintrack AI',
              style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            PremiumAction(
              onTap: () {
                if (!isAuthenticated) {
                  // Уже вылогинен (или ещё не успели инициировать), просто на логин
                  Navigator.pushNamed(context, '/login');
                } else if (isGuest) {
                  _showGuestPremiumDialog(context);
                } else {
                  Navigator.pushNamed(context, '/paywall');
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Выйти',
              onPressed: () async {
                // 1) сбрасываем локальный кэш права, чтобы новый пользователь не увидел старый ENTITLED
                final iapRepo = context.read<IapRepository>();
                await iapRepo.cacheEntitlement(EntitlementStatus.none);
                context.read<PurchaseBloc>().add(PurchaseRefreshEntitlement());

                // 2) диспатчим логаут
                if (context.mounted) {
                  context.read<AuthBloc>().add(LogoutRequested());
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _reload,
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (ctx, state) {
                final slivers = <Widget>[
                  // Collapsing header с балансом + stretch-to-refresh
                  SliverAppBar(
                    pinned: true,
                    stretch: true,
                    expandedHeight: 180,
                    stretchTriggerOffset: 120,
                    onStretchTrigger: _reload,
                    backgroundColor: Theme.of(context).colorScheme.background,
                    flexibleSpace: switch (state) {
                      DashboardLoaded(:final data) => FlexibleSpaceBar(
                          titlePadding: const EdgeInsets.only(
                              left: 16, bottom: 12, right: 16),
                          collapseMode: CollapseMode.parallax,
                          title: _BalanceTitle(balance: data.balance),
                          background: _BalanceBackdrop(
                            income: data.totalIncome,
                            expense: data.totalExpense,
                          ),
                        ),
                      DashboardLoading() => const FlexibleSpaceBar(
                          titlePadding: EdgeInsets.only(left: 16, bottom: 12),
                          title: Text('Загрузка...'),
                        ),
                      DashboardError() => const FlexibleSpaceBar(
                          titlePadding: EdgeInsets.only(left: 16, bottom: 12),
                          title: Text('Ошибка'),
                        ),
                      _ => const FlexibleSpaceBar(),
                    },
                  ),

                  // Быстрые фильтры + выбор периода + AI-карточка
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _QuickFiltersBar(
                            selected: _filter,
                            onSelected: _applyFilter,
                          ),
                          const SizedBox(height: 10),
                          _YearMonthPicker(
                            year: _year,
                            month: _month,
                            onChanged: (y, m) {
                              setState(() {
                                _year = y;
                                _month = m;
                                _day =
                                    null; // ручной выбор месяца отключает "сегодня"
                                _filter = m == null
                                    ? _QuickFilter.all
                                    : _QuickFilter.month;
                              });
                              _reload();
                            },
                          ),
                          const SizedBox(height: 12),
                          if (!isAuthenticated)
                            const SizedBox.shrink()
                          else if (isGuest)
                            const _GuestAiStub()
                          else
                            EntitlementGuard(
                              onOpenPaywall: () =>
                                  Navigator.pushNamed(context, '/paywall'),
                              child: AiAnalyzeCard(
                                year: _year,
                                month: _month ?? DateTime.now().month,
                                currency: currency.code,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Sticky period label
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      minHeight: 52,
                      maxHeight: 52,
                      child: Material(
                        color: Theme.of(context).colorScheme.background,
                        elevation: 0.5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: switch (state) {
                              DashboardLoaded(:final data) => Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      data.periodLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              _ => const SizedBox.shrink(),
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Итоги периода
                  switch (state) {
                    DashboardLoaded(:final data) => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: _PeriodSummary(data: data),
                        ),
                      ),
                    DashboardLoading() =>
                      const SliverToBoxAdapter(child: _LoadingShimmer()),
                    DashboardError(:final message) => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _ErrorView(message: message, onRetry: _reload),
                        ),
                      ),
                    _ => const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  },

                  // Последние транзакции
                  switch (state) {
                    DashboardLoaded(:final data) => data
                            .recentTransactions.isEmpty
                        ? const SliverToBoxAdapter(
                            child: _EmptyRecent(),
                          )
                        : SliverList.separated(
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemCount: data.recentTransactions.length + 2,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.history, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Последние транзакции',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                  fontWeight: FontWeight.w600)),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () => Navigator.pushNamed(
                                            context, '/transactions'),
                                        child: const Text('Все ➔'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              if (index == data.recentTransactions.length + 1) {
                                return const SizedBox(height: 90);
                              }
                              final tx = data.recentTransactions[index - 1];
                              return _RecentTxTile(tx: tx);
                            },
                          ),
                    DashboardLoading() => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _LoadingSkeleton(),
                      ),
                    _ => const SliverToBoxAdapter(child: SizedBox()),
                  },
                ];

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: slivers,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────── Widgets ──────────────────────────────────

class _QuickFiltersBar extends StatelessWidget {
  final _QuickFilter selected;
  final void Function(_QuickFilter) onSelected;

  const _QuickFiltersBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const items = [
      (_QuickFilter.all, 'Все'),
      (_QuickFilter.month, 'Месяц'),
      (_QuickFilter.today, 'Сегодня'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((e) {
          final isSel = selected == e.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(e.$2),
              selected: isSel,
              onSelected: (_) => onSelected(e.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BalanceTitle extends StatelessWidget {
  final double balance;

  const _BalanceTitle({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.account_balance_wallet_rounded, size: 20),
        const SizedBox(width: 8),
        _CountUp(balance),
      ],
    );
  }
}

class _BalanceBackdrop extends StatelessWidget {
  final double income, expense;

  const _BalanceBackdrop({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withOpacity(.35),
            cs.secondaryContainer.withOpacity(.2)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Mini(label: 'Доходы', value: income, color: Colors.green),
            _Mini(label: 'Расходы', value: expense, color: Colors.red),
          ],
        ),
      ),
    );
  }
}

class _CountUp extends StatelessWidget {
  final double value;

  const _CountUp(this.value);

  @override
  Widget build(BuildContext ctx) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        curve: Curves.easeOutBack,
        duration: const Duration(milliseconds: 700),
        builder: (_, v, __) => Text(
          CurrencyFormatter.format(v, ctx),
          style: Theme.of(ctx)
              .textTheme
              .titleLarge!
              .copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

class _YearMonthPicker extends StatelessWidget {
  final int year;
  final int? month;
  final void Function(int year, int? month) onChanged;

  const _YearMonthPicker({
    required this.year,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final nowYear = DateTime.now().year;
    final years = [for (var y = 2023; y <= nowYear; y++) y];

    return Row(
      children: [
        Expanded(
          child: DropdownButton<int>(
            isExpanded: true,
            value: year,
            onChanged: (y) => onChanged(y!, month),
            items: years
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<int?>(
            isExpanded: true,
            value: month,
            hint: const Text('Месяц'),
            onChanged: (m) => onChanged(year, m),
            items: List.generate(12, (i) => i + 1)
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(DateFormat.MMMM('ru').format(DateTime(0, m))),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _Mini({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(value, context),
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      );
}

class _PeriodSummary extends StatelessWidget {
  final dynamic data;

  const _PeriodSummary({required this.data});

  @override
  Widget build(BuildContext context) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ColumnChange(
                amount:
                    '+${CurrencyFormatter.format(data.currentPeriodIncome, context)}',
                label: 'Доходы',
                color: Colors.green,
              ),
              _ColumnChange(
                amount:
                    '-${CurrencyFormatter.format(data.currentPeriodExpense, context)}',
                label: 'Расходы',
                color: Colors.red,
              ),
            ],
          ),
        ),
      );
}

class _ColumnChange extends StatelessWidget {
  final String amount, label;
  final Color color;

  const _ColumnChange({
    required this.amount,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(amount,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ]);
}

class _RecentTxTile extends StatelessWidget {
  final LocalizedTransactionResponseDto tx;

  const _RecentTxTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(tx.category.color);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    TransactionDetailScreen(transaction: tx.toResponse())),
          );
          if (updated == true && context.mounted) {
            dashboardRefreshNotifier.value = true;
          }
        },
        leading: Hero(
          tag: 'tx_${tx.id}_icon',
          child: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 25,
            child:
                Icon(_iconFromString(tx.category.icon), color: color, size: 28),
          ),
        ),
        title: Text(
          tx.category.name,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('d MMM', 'ru').format(tx.date),
                style: Theme.of(context).textTheme.bodySmall),
            if ((tx.comment ?? '').isNotEmpty)
              Text(
                tx.comment!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: Colors.grey),
              ),
          ],
        ),
        trailing: Text(
          '${tx.type.name == 'EXPENSE' ? '-' : '+'}'
          '${CurrencyFormatter.format(tx.amount, context)}',
          style: TextStyle(
            color: tx.type.name == 'EXPENSE' ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.history, size: 20),
              const SizedBox(width: 8),
              Text('Последние транзакции',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Нет транзакций за этот период',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/transactions'),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить транзакцию'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Не удалось загрузить данные',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ]),
        ),
      );
}

// ───────────────────────────── helpers / shared ─────────────────────────────

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight, maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) => Center(
        child: CircularProgressIndicator(
            strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
      );
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(.35),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
}

class _GuestAiStub extends StatelessWidget {
  const _GuestAiStub();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cs.surfaceVariant.withOpacity(.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'AI-анализ доступен после регистрации',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте аккаунт, чтобы сохранять историю, получать персональные инсайты '
              'и оформить Premium, не потеряв доступ.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _showGuestPremiumDialog(context),
                  icon: const Icon(Icons.login),
                  label: const Text('Войти / Зарегистрироваться'),
                )),
          ],
        ),
      ),
    );
  }
}

void _showGuestPremiumDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Доступно только для аккаунта'),
      content: const Text(
        'Вы сейчас в гостевом режиме.\n'
        'Создайте аккаунт, чтобы оформить подписку и не потерять доступ к Premium.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Потом'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.pushNamed(context, '/login');
          },
          child: const Text('Войти / Зарегистрироваться'),
        ),
      ],
    ),
  );
}

// вынеси iconMap в общее место в проекте
IconData _iconFromString(String icon) => iconMap[icon] ?? Icons.category;

Color hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
