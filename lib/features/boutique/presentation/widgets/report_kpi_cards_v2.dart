import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/app/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';
import 'dashboard_kpi_card.dart';

/// KPI cards for reports module - style eau_minerale.
class ReportKpiCardsV2 extends ConsumerWidget {
  const ReportKpiCardsV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportDataAsync = ref.watch(
      reportDataProvider((
        period: ReportPeriod.custom,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    final theme = Theme.of(context);
    return reportDataAsync.when(
      data: (data) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            return isWide
                ? Column(
                    children: [
                      _buildStockValuationCard(ref, theme),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DashboardKpiCard(
                          label: "Chiffre d'Affaires",
                          value:
                              '${CurrencyFormatter.formatFCFA(data.salesRevenue)} FCFA',
                          subtitle: '${data.salesCount} ventes',
                          icon: Icons.trending_up,
                          iconColor: const Color(0xFF3B82F6),
                          backgroundColor: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Achats',
                          value:
                              '${CurrencyFormatter.formatFCFA(data.purchasesAmount)} FCFA',
                          subtitle: '${data.purchasesCount} appros',
                          icon: Icons.shopping_bag,
                          iconColor: const Color(0xFFF59E0B),
                          backgroundColor: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Dépenses',
                          value:
                              '${CurrencyFormatter.formatFCFA(data.expensesAmount)} FCFA',
                          subtitle: '${data.expensesCount} charges',
                          icon: Icons.receipt_long,
                          iconColor: theme.colorScheme.error,
                          valueColor: theme.colorScheme.error,
                          backgroundColor: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Bénéfice Net',
                          value:
                              '${CurrencyFormatter.formatFCFA(data.profit)} FCFA',
                          subtitle: data.profit >= 0 ? 'Profit' : 'Déficit',
                          icon: Icons.account_balance_wallet,
                          iconColor: data.profit >= 0
                              ? AppColors.success
                              : theme.colorScheme.error,
                          valueColor: data.profit >= 0
                              ? AppColors.success
                              : theme.colorScheme.error,
                          backgroundColor: data.profit >= 0
                              ? AppColors.success
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                    children: [
                      _buildStockValuationCard(ref, theme),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DashboardKpiCard(
                              label: "Chiffre d'Affaires",
                              value:
                                  '${CurrencyFormatter.formatFCFA(data.salesRevenue)} FCFA',
                              subtitle: '${data.salesCount} ventes',
                              icon: Icons.trending_up,
                              iconColor: const Color(0xFF3B82F6),
                              backgroundColor: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DashboardKpiCard(
                              label: 'Achats',
                              value:
                                  '${CurrencyFormatter.formatFCFA(data.purchasesAmount)} FCFA',
                              subtitle: '${data.purchasesCount} appros',
                              icon: Icons.shopping_bag,
                              iconColor: const Color(0xFFF59E0B),
                              backgroundColor: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DashboardKpiCard(
                              label: 'Dépenses',
                              value:
                                  '${CurrencyFormatter.formatFCFA(data.expensesAmount)} FCFA',
                              subtitle: '${data.expensesCount} charges',
                              icon: Icons.receipt_long,
                              iconColor: theme.colorScheme.error,
                              valueColor: theme.colorScheme.error,
                              backgroundColor: theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DashboardKpiCard(
                              label: 'Bénéfice Net',
                              value:
                                  '${CurrencyFormatter.formatFCFA(data.profit)} FCFA',
                              subtitle: data.profit >= 0 ? 'Profit' : 'Déficit',
                              icon: Icons.account_balance_wallet,
                              iconColor: data.profit >= 0
                                  ? AppColors.success
                                  : theme.colorScheme.error,
                              valueColor: data.profit >= 0
                                  ? AppColors.success
                                  : theme.colorScheme.error,
                              backgroundColor: data.profit >= 0
                                  ? AppColors.success
                                  : theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
          },
        );
      },
      loading: () => AppShimmers.statsGrid(context),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStockValuationCard(WidgetRef ref, ThemeData theme) {
    final valuationAsync = ref.watch(stockValuationProvider);

    return valuationAsync.when(
      data: (value) => DashboardKpiCard(
        label: 'Valeur Totale du Stock',
        value: '${CurrencyFormatter.formatFCFA(value)} FCFA',
        subtitle: 'Capital immobilisé en stock',
        icon: Icons.inventory_2,
        iconColor: const Color(0xFF8B5CF6), // Purple 500
        backgroundColor: const Color(0xFF8B5CF6),
      ),
      loading: () => ElyfShimmer(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
