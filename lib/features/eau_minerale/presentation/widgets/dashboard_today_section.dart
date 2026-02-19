import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../widgets/z_report_dialog.dart';

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
            final isWide = constraints.maxWidth > 900;
            final cards = [
              ElyfStatsCard(
                label: 'Chiffre d\'Affaires',
                value: CurrencyFormatter.formatFCFA(todayRevenue),
                subtitle: '$todaySalesCount vente(s)',
                icon: Icons.trending_up,
                color: Colors.blue,
              ),
              ElyfStatsCard(
                label: 'Encaissements',
                value: CurrencyFormatter.formatFCFA(todayCollections),
                subtitle: '$collectionRate% collecté',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              ElyfStatsCard(
                label: 'Production du Jour',
                value: '${summary.productionVolume} packs',
                subtitle: summary.productionVolume > 0 ? 'En cours' : 'Aucune session',
                icon: Icons.factory_outlined,
                color: Colors.purple,
              ),
              _TreasuryStatusCard(onTap: () {
                showDialog(context: context, builder: (context) => const ZReportDialog());
              }),
            ];

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[2]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[3]),
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[1]),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
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
      },
      loading: () => Column(
        children: [
          ElyfShimmer(child: ElyfShimmer.listTile()),
        ],
      ),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        onRetry: () => ref.refresh(dailyDashboardSummaryProvider),
      ),
    );
  }
}

class _TreasuryStatusCard extends ConsumerWidget {
  const _TreasuryStatusCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(currentClosingSessionProvider);

    return sessionAsync.when(
      data: (session) {
        final isOpen = session != null;
        return ElyfStatsCard(
          label: 'Trésorerie',
          value: isOpen ? 'OUVERTE' : 'À OUVRIR',
          subtitle: isOpen ? 'Cliquer pour Z-Report' : 'Ouvrir la session',
          icon: isOpen ? Icons.lock_open : Icons.lock_clock,
          color: isOpen ? Colors.green : Colors.orange,
          onTap: onTap,
        );
      },
      loading: () => const ElyfShimmer(child: ElyfStatsCard(label: '...', value: '...', icon: Icons.lock)),
      error: (_, __) => const ElyfStatsCard(label: 'Trésorerie', value: 'Erreur', icon: Icons.error, color: Colors.red),
    );
  }
}
