import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final DateTime endDate;)(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]} ',
            );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportDataAsync = ref.watch(
      reportDataProvider((
        period: ReportPeriod.custom,
        startDate: startDate,
        endDate: endDate,
      )),
    );

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
                          label: "Chiffre d'Affaires",
                          value: '${CurrencyFormatter.formatFCFA(data.salesRevenue)} FCFA',
                          subtitle: '${data.salesCount} ventes',
                          icon: Icons.trending_up,
                          iconColor: Colors.blue,
                          backgroundColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Achats',
                          value: '${CurrencyFormatter.formatFCFA(data.purchasesAmount)} FCFA',
                          subtitle: '${data.purchasesCount} appros',
                          icon: Icons.shopping_bag,
                          iconColor: Colors.orange,
                          backgroundColor: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Dépenses',
                          value: '${CurrencyFormatter.formatFCFA(data.expensesAmount)} FCFA',
                          subtitle: '${data.expensesCount} charges',
                          icon: Icons.receipt_long,
                          iconColor: Colors.red,
                          valueColor: Colors.red.shade700,
                          backgroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardKpiCard(
                          label: 'Bénéfice Net',
                          value: '${CurrencyFormatter.formatFCFA(data.profit)} FCFA',
                          subtitle: data.profit >= 0 ? 'Profit' : 'Déficit',
                          icon: Icons.account_balance_wallet,
                          iconColor:
                              data.profit >= 0 ? Colors.green : Colors.red,
                          valueColor: data.profit >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          backgroundColor:
                              data.profit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DashboardKpiCard(
                              label: "Chiffre d'Affaires",
                              value: '${CurrencyFormatter.formatFCFA(data.salesRevenue)} FCFA',
                              subtitle: '${data.salesCount} ventes',
                              icon: Icons.trending_up,
                              iconColor: Colors.blue,
                              backgroundColor: Colors.blue,
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
                              iconColor: Colors.orange,
                              backgroundColor: Colors.orange,
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
                              iconColor: Colors.red,
                              valueColor: Colors.red.shade700,
                              backgroundColor: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DashboardKpiCard(
                              label: 'Bénéfice Net',
                              value: '${CurrencyFormatter.formatFCFA(data.profit)} FCFA',
                              subtitle: data.profit >= 0 ? 'Profit' : 'Déficit',
                              icon: Icons.account_balance_wallet,
                              iconColor:
                                  data.profit >= 0 ? Colors.green : Colors.red,
                              valueColor: data.profit >= 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              backgroundColor:
                                  data.profit >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
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
