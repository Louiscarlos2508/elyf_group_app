import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';

import 'dashboard_kpi_card.dart';

/// Section displaying today's KPIs.
class DashboardTodaySection extends ConsumerWidget {
  const DashboardTodaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailySummaryAsync = ref.watch(dailyDashboardSummaryProvider);

    return dailySummaryAsync.when(
      data: (summary) {
        final todayRevenue = summary.revenue;
        final todaySalesCount = summary.salesCount;
        final todayCollections = summary.collections;
        final collectionRate = todayRevenue > 0
            ? ((todayCollections / todayRevenue) * 100).toStringAsFixed(0)
            : '0';

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final cards = [
              DashboardKpiCard(
                label: 'Chiffre d\'Affaires',
                value: CurrencyFormatter.formatCFA(todayRevenue),
                subtitle: '$todaySalesCount vente(s)',
                icon: Icons.trending_up,
                iconColor: Colors.blue,
                backgroundColor: Colors.blue,
              ),
              DashboardKpiCard(
                label: 'Encaissements',
                value: CurrencyFormatter.formatCFA(todayCollections),
                subtitle: '$collectionRate% collecté',
                icon: Icons.attach_money,
                iconColor: Colors.green,
                valueColor: Colors.green.shade700,
                backgroundColor: Colors.green,
              ),
            ];

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                ],
              );
            }

            return Column(
              children: [cards[0], const SizedBox(height: 16), cards[1]],
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        onRetry: () => ref.refresh(dailyDashboardSummaryProvider),
      ),
    );
  }
}
