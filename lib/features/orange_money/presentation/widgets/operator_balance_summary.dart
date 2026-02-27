import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

class OperatorBalanceSummary extends ConsumerWidget {
  const OperatorBalanceSummary({super.key, this.enterpriseId});

  final String? enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveId = enterpriseId ?? ref.watch(activeEnterpriseProvider).value?.id ?? '';
    if (effectiveId.isEmpty) return const SizedBox.shrink();

    final balancesAsync = ref.watch(orangeMoneyTreasuryBalanceProvider(effectiveId));
    final theme = Theme.of(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return balancesAsync.when(
      data: (balances) {
        final cash = balances['cash'] ?? 0;
        final mobileMoney = balances['mobileMoney'] ?? 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(isKeyboardOpen ? 10 : 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              _buildBalanceItem(
                context,
                'Cash',
                cash,
                Icons.payments_outlined,
                theme.colorScheme.primary,
                isKeyboardOpen,
              ),
              Container(
                width: 1,
                height: isKeyboardOpen ? 24 : 40,
                margin: EdgeInsets.symmetric(horizontal: isKeyboardOpen ? 8 : 16),
                color: theme.colorScheme.outlineVariant,
              ),
              _buildBalanceItem(
                context,
                'Float SIM',
                mobileMoney,
                Icons.account_balance_wallet_outlined,
                theme.colorScheme.secondary,
                isKeyboardOpen,
              ),
            ],
          ),
        );
      },
      loading: () => SizedBox(height: isKeyboardOpen ? 40 : 80, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String label,
    int amount,
    IconData icon,
    Color color,
    bool isKeyboardOpen,
  ) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');

    return Expanded(
      child: Row(
        children: [
          if (!isKeyboardOpen) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: isKeyboardOpen ? 10 : 11,
                  ),
                ),
                Text(
                  '${fmt.format(amount)}',
                  style: (isKeyboardOpen ? theme.textTheme.bodyMedium : theme.textTheme.titleMedium)?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
