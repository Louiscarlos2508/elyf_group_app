import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';

class PurchaseReportContent extends ConsumerWidget {
  const PurchaseReportContent({
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
    final purchasesReportAsync = ref.watch(
      purchasesReportProvider((
        period: period,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    return purchasesReportAsync.when(
      data: (report) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rapport des Achats',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatRow(theme, 'Montant total des achats', _formatCurrency(report.totalAmount)),
                _buildStatRow(theme, 'Nombre d\'achats', '${report.purchasesCount}'),
                _buildStatRow(theme, 'Articles achetés', '${report.totalItemsPurchased}'),
                _buildStatRow(theme, 'Montant moyen par achat', _formatCurrency(report.averagePurchaseAmount)),
                const Divider(height: 32),
                if (report.topSuppliers.isNotEmpty) ...[
                  Text(
                    'Top Fournisseurs',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...report.topSuppliers.map((supplier) {
                    return ListTile(
                      leading: const Icon(Icons.business),
                      title: Text(supplier.supplierName),
                      subtitle: Text('${supplier.purchasesCount} achat(s)'),
                      trailing: Text(
                        _formatCurrency(supplier.totalAmount),
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

