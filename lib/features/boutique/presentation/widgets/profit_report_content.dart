import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';

class ProfitReportContent extends ConsumerWidget {
  const ProfitReportContent({
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
    final theme = Theme.of(context);
    final profitReportAsync = ref.watch(
      profitReportProvider((
        period: period,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    return profitReportAsync.when(
      data: (report) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rapport des Bénéfices',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatRow(theme, 'Chiffre d\'affaires', _formatCurrency(report.totalRevenue)),
                _buildStatRow(theme, 'Coût des marchandises vendues', _formatCurrency(report.totalCostOfGoodsSold)),
                _buildStatRow(theme, 'Marge brute', _formatCurrency(report.grossProfit), Colors.green),
                _buildStatRow(theme, 'Taux de marge brute', '${report.grossMarginPercentage.toStringAsFixed(1)}%', Colors.green),
                const Divider(height: 32),
                _buildStatRow(theme, 'Dépenses totales', _formatCurrency(report.totalExpenses)),
                _buildStatRow(theme, 'Bénéfice net', _formatCurrency(report.netProfit), 
                  report.netProfit >= 0 ? Colors.purple : Colors.red),
                _buildStatRow(theme, 'Taux de marge nette', '${report.netMarginPercentage.toStringAsFixed(1)}%',
                  report.netProfit >= 0 ? Colors.purple : Colors.red),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Erreur de chargement'),
    );
  }

  Widget _buildStatRow(ThemeData theme, String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

