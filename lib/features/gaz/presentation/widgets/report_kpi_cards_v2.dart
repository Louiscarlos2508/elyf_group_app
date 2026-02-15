import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/stock_movement.dart';
import '../../../../../shared.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;

/// KPI cards for gaz reports module - style eau_minerale.
class GazReportKpiCardsV2 extends ConsumerWidget {
  const GazReportKpiCardsV2({
    super.key,
    required this.startDate,
    required this.endDate,
    this.selectedTab = 0,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int selectedTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportDataAsync = ref.watch(
      gazReportDataProvider((
        period: GazReportPeriod.custom,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    if (selectedTab == 3) {
      return _buildStockKpis(context, ref);
    }

    return reportDataAsync.when(
      data: (data) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Row(
                children: [
                  Expanded(
                    child: ElyfStatsCard(
                      label: "Chiffre d'Affaires",
                      value: CurrencyFormatter.formatDouble(data.salesRevenue),
                      subtitle: '${data.salesCount} ventes',
                      icon: Icons.trending_up,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElyfStatsCard(
                      label: 'Dépenses',
                      value: CurrencyFormatter.formatDouble(data.expensesAmount),
                      subtitle: '${data.expensesCount} charges',
                      icon: Icons.receipt_long,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElyfStatsCard(
                      label: 'Bénéfice Net',
                      value: CurrencyFormatter.formatDouble(data.profit),
                      subtitle: data.profit >= 0 ? 'Profit' : 'Déficit',
                      icon: Icons.account_balance_wallet,
                      color: data.profit >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                ElyfStatsCard(
                  label: "Chiffre d'Affaires",
                  value: CurrencyFormatter.formatDouble(data.salesRevenue),
                  subtitle: '${data.salesCount} ventes',
                  icon: Icons.trending_up,
                  color: Colors.blue,
                ),
                const SizedBox(height: AppSpacing.md),
                ElyfStatsCard(
                  label: 'Dépenses',
                  value: CurrencyFormatter.formatDouble(data.expensesAmount),
                  subtitle: '${data.expensesCount} charges',
                  icon: Icons.receipt_long,
                  color: Colors.red,
                ),
                const SizedBox(height: AppSpacing.md),
                ElyfStatsCard(
                  label: 'Bénéfice Net',
                  value: CurrencyFormatter.formatDouble(data.profit),
                  subtitle: data.profit >= 0 ? 'Profit' : 'Déficit',
                  icon: Icons.account_balance_wallet,
                  color: data.profit >= 0 ? Colors.green : Colors.red,
                ),
              ],
            );
          },
        );
      },
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStockKpis(BuildContext context, WidgetRef ref) {
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    final enterpriseId = activeEnterpriseAsync.when(
      data: (e) => e?.id ?? '',
      loading: () => '',
      error: (_, __) => '',
    );

    if (enterpriseId.isEmpty) return const SizedBox.shrink();

    final summaryAsync = ref.watch(gazStockSummaryProvider((enterpriseId: enterpriseId, siteId: null)));
    final historyAsync = ref.watch(gazStockHistoryProvider((enterpriseId: enterpriseId, startDate: startDate, endDate: endDate, siteId: null)));

    return summaryAsync.when(
      data: (summary) {
        int totalFull = 0;
        int totalEmpty = 0;
        for (final weightSummary in summary.values) {
          totalFull += weightSummary[CylinderStatus.full] ?? 0;
          totalEmpty += (weightSummary[CylinderStatus.emptyAtStore] ?? 0) + (weightSummary[CylinderStatus.emptyInTransit] ?? 0);
        }

        final totalLeaks = historyAsync.maybeWhen(
          data: (movements) => movements.where((m) => m.type == StockMovementType.leak).length,
          orElse: () => 0,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final cards = [
              ElyfStatsCard(
                label: 'Stock Plein',
                value: '$totalFull',
                subtitle: 'Bouteilles pleines',
                icon: Icons.inventory_2,
                color: Colors.green,
              ),
              ElyfStatsCard(
                label: 'Stock Vide',
                value: '$totalEmpty',
                subtitle: 'Bouteilles vides',
                icon: Icons.shopping_basket_outlined,
                color: Colors.blue,
              ),
              ElyfStatsCard(
                label: 'Fuites',
                value: '$totalLeaks',
                subtitle: 'Incidents fuites',
                icon: Icons.water_drop_outlined,
                color: Colors.orange,
              ),
            ];

            if (isWide) {
              return Row(
                children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: AppSpacing.md), child: c))).toList(),
              );
            }

            return Column(
              children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: c)).toList(),
            );
          },
        );
      },
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
