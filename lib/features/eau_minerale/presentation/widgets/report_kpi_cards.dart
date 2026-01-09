import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/report_period.dart';
import 'dashboard_kpi_card.dart';

/// KPI cards for reports module.
class ReportKpiCards extends ConsumerWidget {
  const ReportKpiCards({
    super.key,
    required this.period,
  });

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
                          iconColor: Colors.blue,
                          backgroundColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Encaissements',
                          value: CurrencyFormatter.formatFCFA(data.collections),
                          subtitle: '${data.collectionRate.toStringAsFixed(0)}% du CA',
                          icon: Icons.attach_money,
                          iconColor: Colors.green,
                          valueColor: Colors.green.shade700,
                          backgroundColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Charges Totales',
                          value: CurrencyFormatter.formatFCFA(data.totalExpenses),
                          subtitle: 'Dépenses + Salaires',
                          icon: Icons.receipt_long,
                          iconColor: Colors.red,
                          valueColor: Colors.red.shade700,
                          backgroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Trésorerie',
                          value: CurrencyFormatter.formatFCFA(data.treasury),
                          subtitle: 'Entrées - Sorties',
                          icon: Icons.trending_up,
                          iconColor: data.treasury >= 0 ? Colors.green : Colors.red,
                          valueColor: data.treasury >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          backgroundColor: data.treasury >= 0 ? Colors.green : Colors.red,
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
                        iconColor: Colors.blue,
                        backgroundColor: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      DashboardKpiCard(
                        label: 'Encaissements',
                        value: CurrencyFormatter.formatFCFA(data.collections),
                        subtitle: '${data.collectionRate.toStringAsFixed(0)}% du CA',
                        icon: Icons.attach_money,
                        iconColor: Colors.green,
                        valueColor: Colors.green.shade700,
                        backgroundColor: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      DashboardKpiCard(
                        label: 'Charges Totales',
                        value: CurrencyFormatter.formatFCFA(data.totalExpenses),
                        subtitle: 'Dépenses + Salaires',
                        icon: Icons.receipt_long,
                        iconColor: Colors.red,
                        valueColor: Colors.red.shade700,
                        backgroundColor: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      DashboardKpiCard(
                        label: 'Trésorerie',
                        value: CurrencyFormatter.formatFCFA(data.treasury),
                        subtitle: 'Entrées - Sorties',
                        icon: Icons.trending_up,
                        iconColor: data.treasury >= 0 ? Colors.green : Colors.red,
                        valueColor: data.treasury >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                        backgroundColor: data.treasury >= 0 ? Colors.green : Colors.red,
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

