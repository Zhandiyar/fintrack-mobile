import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/model/entitlement_status.dart';
import '../bloc/purchase_bloc.dart';


class PremiumAction extends StatelessWidget {
  final VoidCallback onTap;
  const PremiumAction({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocSelector<PurchaseBloc, PurchaseState, EntitlementStatus>(
      selector: (s) => s.status,
      builder: (context, status) {
        final isActive = status.isUnlocked;

        // В топ-приложениях часто показывают “чип”
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isActive
                    ? LinearGradient(colors: [cs.primary, cs.secondary])
                    : null,
                color: isActive ? null : cs.surfaceVariant.withOpacity(.5),
                border: isActive ? null : Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium,
                      size: 18, color: isActive ? Colors.white : cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    isActive ? 'Premium' : 'Оформить',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
