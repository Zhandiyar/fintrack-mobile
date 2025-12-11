import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/blocs/auth_bloc.dart';
import '../../../auth/blocs/auth_state.dart';
import '../../domain/model/entitlement_status.dart';
import '../../iap_ids.dart';
import '../bloc/purchase_bloc.dart';
import '../bloc/purchase_event.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FinTrack Premium')),
      body: SafeArea(
        child: BlocListener<PurchaseBloc, PurchaseState>(
          listenWhen: (prev, next) =>
              !prev.status.isUnlocked && next.status.isUnlocked,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Premium активирован. Спасибо!')),
            );
          },
          child: BlocConsumer<PurchaseBloc, PurchaseState>(
            // Здесь слушаем ТОЛЬКО ошибки
            listenWhen: (prev, next) => prev.lastError != next.lastError,
            listener: (context, s) {
              if (s.lastError != null && s.lastError!.trim().isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.lastError!)),
                );
              }
            },
            builder: (context, s) {
              final authState = context.watch<AuthBloc>().state;

              final bool isGuest =
                  authState is AuthAuthenticated && authState.isGuest;

              // если гость — вообще не показываем планы и кнопки оплаты
              if (isGuest) {
                return const _GuestPaywallStub();
              }

              final entitled = s.status.isUnlocked;

              final monthly = s.products
                  .where((p) => p.id == IapIds.monthly)
                  .cast<ProductDetails?>()
                  .firstOrNull;
              final yearly = s.products
                  .where((p) => p.id == IapIds.yearly)
                  .cast<ProductDetails?>()
                  .firstOrNull;

              // ≈ "выгоднее": сравним effective per month
              double? savePct;
              if (monthly != null && yearly != null) {
                final m = monthly.rawPrice;
                final y = yearly.rawPrice / 12.0;
                if (m > 0 && y > 0 && y < m) {
                  savePct = ((1 - y / m) * 100).roundToDouble();
                }
              }

              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      if (!s.storeAvailable)
                        const _InfoBanner(
                            text: 'Google Play недоступен на устройстве'),
                      if (entitled)
                        const _InfoBanner(
                          text:
                              'Подписка активна. Доступ к AI-анализу и отчётам открыт.',
                          isError: false,
                        )
                      else
                        const _Header(),

                      const SizedBox(height: 12),
                      const _Benefits(),
                      const SizedBox(height: 12),

                      if (monthly == null && yearly == null)
                        const _ProductsSkeleton()
                      else
                        Column(
                          children: [
                            if (yearly != null)
                              _PlanCard(
                                title: 'Годовая',
                                product: yearly,
                                highlight: savePct != null,
                                badgeText: savePct != null
                                    ? '−${savePct.toInt()}% выгоднее'
                                    : null,
                                active: entitled,
                                onBuy: () => context
                                    .read<PurchaseBloc>()
                                    .add(PurchaseBuy(yearly)),
                                busy: s.isBusy,
                              ),
                            const SizedBox(height: 12),
                            if (monthly != null)
                              _PlanCard(
                                title: 'Месячная',
                                product: monthly,
                                active: entitled,
                                onBuy: () => context
                                    .read<PurchaseBloc>()
                                    .add(PurchaseBuy(monthly)),
                                busy: s.isBusy,
                              ),
                          ],
                        ),

                      const SizedBox(height: 12),

                      // действия: оборачиваем в Wrap, чтобы не обрезались на маленьких экранах
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ActionButton(
                            icon: Icons.refresh,
                            label: 'Восстановить покупки',
                            onPressed: s.isBusy
                                ? null
                                : () {
                                    context
                                        .read<PurchaseBloc>()
                                        .add(PurchaseRestore());
                                  },
                            busy:
                                s.isBusy && s.busyAction == BusyAction.restore,
                          ),
                          _ActionButton(
                            icon: Icons.verified_user_outlined,
                            label: 'Проверить статус',
                            onPressed: s.isBusy
                                ? null
                                : () {
                                    context
                                        .read<PurchaseBloc>()
                                        .add(PurchaseRefreshEntitlement());
                                  },
                            busy: s.isBusy &&
                                s.busyAction == BusyAction.refreshEnt,
                          ),
                          _OutlinedAction(
                            icon: Icons.settings_outlined,
                            label: 'Управлять подпиской',
                            onPressed: () => _openManageSubscription(),
                          ),
                          _OutlinedAction(
                            icon: Icons.credit_card,
                            label: 'Платёжные способы',
                            onPressed: _openPaymentMethods,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      // юридический блок с ССЫЛКАМИ — подставь реальные URL
                      const _LegalLinks(
                        termsUrl:
                            'https://zhandiyar.github.io/fintrack-mobile/terms.html',
                        privacyUrl:
                            'https://zhandiyar.github.io/fintrack-mobile/privacy-policy.html',
                      ),
                      const SizedBox(height: 8),
                      const _LegalNote(),
                    ],
                  ),

                  // общий overlay-лоадер — когда что-то происходит
                  if (s.isBusy)
                    IgnorePointer(
                      ignoring: true,
                      child: Container(
                        color: Colors.black.withOpacity(0.04),
                        alignment: Alignment.topCenter,
                        child: const LinearProgressIndicator(minHeight: 2),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // deep link в центр подписок (опционально можно добавить sku)
  Future<void> _openManageSubscription({String? sku}) async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?package=${IapIds.packageName}${sku != null ? '&sku=$sku' : ''}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPaymentMethods() async {
    final uri = Uri.parse('https://payments.google.com/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          Icon(Icons.workspace_premium, color: Colors.white, size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Прокачай FinTrack\nДетальный AI-анализ и отчёты',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  final bool isError;

  const _InfoBanner({required this.text, this.isError = true});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg =
        isError ? Colors.red.withOpacity(.1) : Colors.green.withOpacity(.1);
    final fg = isError ? Colors.red : Colors.green;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fg.withOpacity(.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: fg,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(color: cs.onSurface))),
          ],
        ),
      ),
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    final items = const [
      'AI-анализ доходов и расходов',
      'Инсайты и рекомендации',
      'Расширенные отчёты и сегменты',
      'Поддержка разработки 💙',
    ];
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceVariant.withOpacity(.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Что входит',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...items.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final ProductDetails product;
  final VoidCallback onBuy;
  final bool highlight;
  final String? badgeText;
  final bool busy;
  final bool active;

  const _PlanCard({
    required this.title,
    required this.product,
    required this.onBuy,
    this.highlight = false,
    this.badgeText,
    required this.busy,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = active; // если уже активна подписка — блокируем покупку

    return Semantics(
      label: '$title план',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight ? cs.primary : cs.outlineVariant,
            width: highlight ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (badgeText != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
            ]),
            const SizedBox(height: 6),
            Text(product.price,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(product.description,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: (busy || disabled) ? null : onBuy,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.workspace_premium),
              label: Text(disabled ? 'Уже активна' : 'Оформить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsSkeleton extends StatelessWidget {
  const _ProductsSkeleton();

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
}

/// Кнопка-действие (заливка)
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon),
      label: Text(label),
    );
  }
}

/// Кнопка-действие (обводка)
class _OutlinedAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _OutlinedAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

/// Юр. ссылки (заполни реальными адресами)
class _LegalLinks extends StatelessWidget {
  final String termsUrl;
  final String privacyUrl;

  const _LegalLinks({required this.termsUrl, required this.privacyUrl});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodySmall!
        .copyWith(decoration: TextDecoration.underline);

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        InkWell(
          onTap: () => _launch(termsUrl),
          child: Text('Условия использования', style: style),
        ),
        InkWell(
          onTap: () => _launch(privacyUrl),
          child: Text('Политика конфиденциальности', style: style),
        ),
      ],
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}


class _GuestPaywallStub extends StatelessWidget {
  const _GuestPaywallStub();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Вы вошли как гость.\n'
                        'Чтобы оформить Premium и не потерять доступ, создайте аккаунт.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              // TODO: переход на экран регистрации / логина
              Navigator.pushNamed(context, '/login');
            },
            icon: const Icon(Icons.login),
            label: const Text('Зарегистрироваться / Войти'),
          ),
          const SizedBox(height: 12),
          Text(
            'Подписка привязывается к вашему аккаунту. '
                'Покупка в гостевом режиме может привести к потере доступа.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _LegalNote extends StatelessWidget {
  const _LegalNote();

  @override
  Widget build(BuildContext context) => Text(
        'Оплата через Google Play. Автопродление можно отключить в настройках подписок Google. '
        'Нажимая «Оформить», вы принимаете Условия использования и Политику конфиденциальности.',
        style:
            Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey),
      );
}

// утилита: безопасный firstOrNull
extension FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
