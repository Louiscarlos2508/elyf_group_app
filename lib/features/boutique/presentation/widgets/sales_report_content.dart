import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/report_data.dart';

class SalesReportContent extends ConsumerWidget {
  const SalesReportContent({
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
    final salesReportAsync = ref.watch(
      salesReportProvider((
        period: period,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    return salesReportAsync.when(
      data: (report) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rapport des Ventes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatRow(theme, 'Chiffre d\'affaires total', _formatCurrency(report.totalRevenue)),
                _buildStatRow(theme, 'Nombre de ventes', '${report.salesCount}'),
                _buildStatRow(theme, 'Articles vendus', '${report.totalItemsSold}'),
                _buildStatRow(theme, 'Montant moyen par vente', _formatCurrency(report.averageSaleAmount)),
                const Divider(height: 32),
                if (report.topProducts.isNotEmpty) ...[
                  Text(
                    'Top Produits',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...report.topProducts.map((product) {
                    return ListTile(
                      leading: const Icon(Icons.shopping_bag),
                      title: Text(product.productName),
                      subtitle: Text('${product.quantitySold} unité(s) vendue(s)'),
                      trailing: Text(
                        _formatCurrency(product.revenue),
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

