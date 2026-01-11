import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../../../core/permissions/modules/eau_minerale_permissions.dart';
/// Action buttons for credit card with permission checks.
class CreditActionButtons extends ConsumerWidget {
  const CreditActionButtons({
    super.key,
    required this.creditsCount,
    required this.onHistoryTap,
    required this.onPaymentTap,
  });

  final int creditsCount;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onPaymentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adapter = ref.watch(eauMineralePermissionAdapterProvider);
    
    return FutureBuilder<Map<String, bool>>(
      future: Future.wait([
        adapter.hasPermission(EauMineralePermissions.viewCreditHistory.id),
        adapter.hasPermission(EauMineralePermissions.collectPayment.id),
      ]).then((results) => {
        'history': results[0],
        'payment': results[1],
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final hasHistoryPermission = snapshot.data?['history'] ?? false;
        final hasPaymentPermission = snapshot.data?['payment'] ?? false;

        if (!hasHistoryPermission && !hasPaymentPermission) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            if (hasHistoryPermission) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onHistoryTap,
                  icon: const Icon(Icons.history, size: 18),
                  label: Text('Historique ($creditsCount)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (hasPaymentPermission) const SizedBox(width: 12),
            ],
            if (hasPaymentPermission)
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPaymentTap,
                  icon: const Icon(Icons.attach_money, size: 18),
                  label: const Text('Encaisser'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

