import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fintrack/features/iap/domain/model/entitlement_status.dart';
import '../bloc/purchase_bloc.dart';

class EntitlementGuard extends StatelessWidget {
  final Widget child;
  final VoidCallback onOpenPaywall;
  final double radius;

  const EntitlementGuard({
    super.key,
    required this.child,
    required this.onOpenPaywall,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PurchaseBloc, PurchaseState, EntitlementStatus>(
      selector: (s) => s.status,
      builder: (context, status) {
        if (status.isUnlocked) return child;

        return Stack(
          children: [
            // не даём тапать по «заблюренному» контенту
            IgnorePointer(ignoring: true, child: child),

            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withOpacity(0.35),
                    alignment: Alignment.center,
                    // Контент всегда влезает: ограничиваем ширину + масштабируем при нехватке места.
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _LockedContent(onOpenPaywall: onOpenPaywall),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LockedContent extends StatelessWidget {
  final VoidCallback onOpenPaywall;
  const _LockedContent({required this.onOpenPaywall});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 28, color: Colors.white),
            const SizedBox(height: 8),
            const Text(
              'Premium-функция',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Оформи подписку, чтобы разблокировать AI-анализ',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onOpenPaywall,
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Открыть Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
