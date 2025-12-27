import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';
import 'dashboard_kpi_card.dart';
import '../../../../shared/utils/currency_formatter.dart';

/// KPI cards for gaz reports module - style eau_minerale.
class GazReportKpiCardsV2 extends ConsumerWidget {
  const GazReportKpiCardsV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

)+(?!\d))'),
              (Match m) => '${m[1]} ',
            ) +
        ' F';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportDataAsync = ref.watch(
      gazReportDataProvider((
        period: GazReportPeriod.custom,
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
                        child: GazDashboardKpiCard(
                          label: "Chiffre d'Affaires",
                          value: '${CurrencyFormatter.formatDouble(data.salesRevenue)}',
                          subtitle: '${data.salesCount} ventes',
                          icon: Icons.trending_up,
                          iconColor: Colors.blue,
                          backgroundColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GazDashboardKpiCard(
                          label: 'Dépenses',
                          value: '${CurrencyFormatter.formatDouble(data.expensesAmount)}',
                          subtitle: '${data.expensesCount} charges',
                          icon: Icons.receipt_long,
                          iconColor: Colors.red,
                          valueColor: Colors.red.shade700,
                          backgroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GazDashboardKpiCard(
                          label: 'Bénéfice Net',
                          value: '${CurrencyFormatter.formatDouble(data.profit)}',
                          subtitle: data.profit >= 0 ? 'Profit' : 'Déficit',
                          icon: Icons.account_balance_wallet,
                          iconColor: data.profit >= 0 ? Colors.green : Colors.red,
                          valueColor: data.profit >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          backgroundColor: data.profit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      GazDashboardKpiCard(
                        label: "Chiffre d'Affaires",
                        value: '${CurrencyFormatter.formatDouble(data.salesRevenue)}',
                        subtitle: '${data.salesCount} ventes',
                        icon: Icons.trending_up,
                        iconColor: Colors.blue,
                        backgroundColor: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      GazDashboardKpiCard(
                        label: 'Dépenses',
                        value: '${CurrencyFormatter.formatDouble(data.expensesAmount)}',
                        subtitle: '${data.expensesCount} charges',
                        icon: Icons.receipt_long,
                        iconColor: Colors.red,
                        valueColor: Colors.red.shade700,
                        backgroundColor: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      GazDashboardKpiCard(
                        label: 'Bénéfice Net',
                        value: '${CurrencyFormatter.formatDouble(data.profit)}',
                        subtitle: data.profit >= 0 ? 'Profit' : 'Déficit',
                        icon: Icons.account_balance_wallet,
                        iconColor: data.profit >= 0 ? Colors.green : Colors.red,
                        valueColor: data.profit >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        backgroundColor: data.profit >= 0 ? Colors.green : Colors.red,
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
}