import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';
import 'dashboard_kpi_card.dart';

class ReportKpiCards extends ConsumerWidget {
  const ReportKpiCards({
    super.key,
    required this.period,
    this.startDate,
    this.endDate,
  });

  final ReportPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(
      reportDataProvider((
        period: period,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    return reportAsync.when(
      data: (report) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            
            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Chiffre d\'Affaires',
                      value: _formatCurrency(report.salesRevenue),
                      subtitle: '${report.salesCount} ventes',
                      icon: Icons.trending_up,
                      iconColor: Colors.green,
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Achats',
                      value: _formatCurrency(report.purchasesAmount),
                      subtitle: '${report.purchasesCount} achats',
                      icon: Icons.shopping_bag,
                      iconColor: Colors.blue,
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Dépenses',
                      value: _formatCurrency(report.expensesAmount),
                      subtitle: '${report.expensesCount} dépenses',
                      icon: Icons.receipt_long,
                      iconColor: Colors.orange,
                      backgroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Bénéfice Net',
                      value: _formatCurrency(report.profit),
                      subtitle: '${report.profitMarginPercentage.toStringAsFixed(1)}% de marge',
                      icon: Icons.account_balance_wallet,
                      iconColor: report.profit >= 0 ? Colors.purple : Colors.red,
                      backgroundColor: report.profit >= 0 ? Colors.purple : Colors.red,
                    ),
                  ),
                ],
              );
            }
            
            return Column(
              children: [
                DashboardKpiCard(
                  label: 'Chiffre d\'Affaires',
                  value: _formatCurrency(report.salesRevenue),
                  subtitle: '${report.salesCount} ventes',
                  icon: Icons.trending_up,
                  iconColor: Colors.green,
                  backgroundColor: Colors.green,
                ),
                const SizedBox(height: 16),
                DashboardKpiCard(
                  label: 'Achats',
                  value: _formatCurrency(report.purchasesAmount),
                  subtitle: '${report.purchasesCount} achats',
                  icon: Icons.shopping_bag,
                  iconColor: Colors.blue,
                  backgroundColor: Colors.blue,
                ),
                const SizedBox(height: 16),
                DashboardKpiCard(
                  label: 'Dépenses',
                  value: _formatCurrency(report.expensesAmount),
                  subtitle: '${report.expensesCount} dépenses',
                  icon: Icons.receipt_long,
                  iconColor: Colors.orange,
                  backgroundColor: Colors.orange,
                ),
                const SizedBox(height: 16),
                DashboardKpiCard(
                  label: 'Bénéfice Net',
                  value: _formatCurrency(report.profit),
                  subtitle: '${report.profitMarginPercentage.toStringAsFixed(1)}% de marge',
                  icon: Icons.account_balance_wallet,
                  iconColor: report.profit >= 0 ? Colors.purple : Colors.red,
                  backgroundColor: report.profit >= 0 ? Colors.purple : Colors.red,
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

