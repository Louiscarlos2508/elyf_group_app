import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';

class ExpenseReportContent extends ConsumerWidget {
  const ExpenseReportContent({
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
    final expensesReportAsync = ref.watch(
      expensesReportProvider((
        period: period,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    return expensesReportAsync.when(
      data: (report) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rapport des Dépenses',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatRow(theme, 'Montant total des dépenses', _formatCurrency(report.totalAmount)),
                _buildStatRow(theme, 'Nombre de dépenses', '${report.expensesCount}'),
                _buildStatRow(theme, 'Montant moyen par dépense', _formatCurrency(report.averageExpenseAmount)),
                const Divider(height: 32),
                if (report.byCategory.isNotEmpty) ...[
                  Text(
                    'Par Catégorie',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...report.byCategory.entries.map((entry) {
                    return ListTile(
                      leading: const Icon(Icons.category),
                      title: Text(entry.key),
                      trailing: Text(
                        _formatCurrency(entry.value),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Erreur de chargement'),
    );
  }

  Widget _buildStatRow(ThemeData theme, String label, String value) {
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
            ),
          ),
        ],
      ),
    );
  }
}

