import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/report_period.dart';
import 'dashboard_kpi_card.dart';

/// KPI cards for reports module.
class ReportKpiCards extends ConsumerWidget {
  const ReportKpiCards({super.key, required this.period});

  final ReportPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportDataAsync = ref.watch(reportDataProvider(period));

    return reportDataAsync.when(
      data: (data) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            return isWide
                ? Row(
                    children: [
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Chiffre d\'Affaires',
                          value: CurrencyFormatter.formatFCFA(data.revenue),
                          subtitle: '${data.salesCount} ventes',
                          icon: Icons.trending_up,
                          iconColor: Colors.blue.shade700,
                          valueColor: Colors.blue.shade800,
                          isGlass: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Encaissements',
                          value: CurrencyFormatter.formatFCFA(data.collections),
                          subtitle:
                              '${data.collectionRate.toStringAsFixed(0)}% du CA',
                          icon: Icons.account_balance_wallet_rounded,
                          iconColor: Colors.green.shade700,
                          valueColor: Colors.green.shade800,
                          isGlass: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Charges Totales',
                          value: CurrencyFormatter.formatFCFA(
                            data.totalExpenses,
                          ),
                          subtitle: 'Dépenses + Salaires',
                          icon: Icons.receipt_long_rounded,
                          iconColor: Colors.red.shade700,
                          valueColor: Colors.red.shade800,
                          isGlass: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Trésorerie',
                          value: CurrencyFormatter.formatFCFA(data.treasury),
                          subtitle: 'Solde Net',
                          icon: Icons.analytics_rounded,
                          iconColor: data.treasury >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          valueColor: data.treasury >= 0
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          isGlass: true,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      DashboardKpiCard(
                        label: 'Chiffre d\'Affaires',
                        value: CurrencyFormatter.formatFCFA(data.revenue),
                        subtitle: '${data.salesCount} ventes',
                        icon: Icons.trending_up,
                        iconColor: Colors.blue.shade700,
                        valueColor: Colors.blue.shade800,
                        isGlass: true,
                      ),
                      const SizedBox(height: 16),
                      DashboardKpiCard(
                        label: 'Encaissements',
                        value: CurrencyFormatter.formatFCFA(data.collections),
                        subtitle:
                            '${data.collectionRate.toStringAsFixed(0)}% du CA',
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: Colors.green.shade700,
                        valueColor: Colors.green.shade800,
                        isGlass: true,
                      ),
                      const SizedBox(height: 16),
                      DashboardKpiCard(
                        label: 'Charges Totales',
                        value: CurrencyFormatter.formatFCFA(data.totalExpenses),
                        subtitle: 'Dépenses + Salaires',
                        icon: Icons.receipt_long_rounded,
                        iconColor: Colors.red.shade700,
                        valueColor: Colors.red.shade800,
                        isGlass: true,
                      ),
                      const SizedBox(height: 16),
                      DashboardKpiCard(
                        label: 'Trésorerie',
                        value: CurrencyFormatter.formatFCFA(data.treasury),
                        subtitle: 'Solde Net',
                        icon: Icons.analytics_rounded,
                        iconColor: data.treasury >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        valueColor: data.treasury >= 0
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        isGlass: true,
                      ),
                    ],
                  );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
