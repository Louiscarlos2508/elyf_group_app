import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/atoms/elyf_shimmer.dart';

/// Section displaying monthly KPIs with production sessions data.
class DashboardMonthKpis extends ConsumerWidget {
  const DashboardMonthKpis({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlyDashboardSummaryProvider);

    return summaryAsync.when(
      data: (summary) => _buildKpis(context, summary),
      loading: () => _buildLoadingState(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        ElyfShimmer(child: ElyfShimmer.listTile()),
        const SizedBox(height: 16),
        ElyfShimmer(child: ElyfShimmer.listTile()),
      ],
    );
  }

  Widget _buildKpis(
    BuildContext context,
    MonthlyDashboardSummary summary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        final theme = Theme.of(context);
        final cards = [
          ElyfStatsCard(
            label: 'Chiffre d\'Affaires',
            value: CurrencyFormatter.formatFCFA(summary.revenue),
            subtitle: '${summary.salesCount} ventes',
            icon: Icons.trending_up,
            color: Colors.blue,
          ),
          ElyfStatsCard(
            label: 'Production',
            value: '${summary.production} packs',
            subtitle: '${summary.sessionsCount} sessions',
            icon: Icons.factory,
            color: Colors.purple,
          ),
          ElyfStatsCard(
            label: 'Dépenses',
            value: CurrencyFormatter.formatFCFA(summary.expenses),
            subtitle: '${summary.transactionsCount} transactions',
            icon: Icons.receipt_long,
            color: theme.colorScheme.error,
          ),
          ElyfStatsCard(
            label: 'Résultat Net',
            value: CurrencyFormatter.formatFCFA(summary.result),
            subtitle: summary.result >= 0 ? 'Bénéfice' : 'Déficit',
            icon: Icons.account_balance_wallet,
            color: summary.result >= 0 ? Colors.green : Colors.red,
          ),
        ];

        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
                const SizedBox(width: 16),
                Expanded(child: cards[2]),
                const SizedBox(width: 16),
                Expanded(child: cards[3]),
              ],
            ),
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 16),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}
