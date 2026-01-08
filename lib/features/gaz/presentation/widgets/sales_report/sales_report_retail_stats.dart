import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart' show gazReportCalculationServiceProvider;
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../../domain/entities/gas_sale.dart';
import '../../../domain/services/gaz_report_calculation_service.dart';
import 'sales_report_helpers.dart';

/// Statistiques des ventes au détail.
class SalesReportRetailStats extends ConsumerWidget {
  const SalesReportRetailStats({
    super.key,
    required this.retailSales,
  });

  final List<GasSale> retailSales;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Utiliser le service de calcul pour extraire la logique métier
    final reportService = ref.read(gazReportCalculationServiceProvider);
    final salesByClient = _groupSalesByClient(retailSales);
    final totalRetail = reportService.calculateRetailTotal(retailSales);
    final totalQuantity = SalesReportHelpers.calculateTotalQuantity(retailSales);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(theme, retailSales.length, totalRetail, totalQuantity),
        const SizedBox(height: 16),
        if (salesByClient.isNotEmpty) _buildTopClients(theme, salesByClient),
      ],
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    int salesCount,
    double totalRetail,
    int totalQuantity,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '$salesCount',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'Vente${salesCount > 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                CurrencyFormatter.formatDouble(totalRetail),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'Total',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '$totalQuantity',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'Bouteille${totalQuantity > 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopClients(
    ThemeData theme,
    Map<String, ({int count, double total})> salesByClient,
  ) {
    final topClients = (salesByClient.entries.toList()
          ..sort((a, b) => b.value.total.compareTo(a.value.total)))
        .take(5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Clients',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...topClients.map((entry) {
          final data = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatDouble(data.total),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${data.count} bouteille${data.count > 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Map<String, ({int count, double total})> _groupSalesByClient(
    List<GasSale> sales,
  ) {
    final result = <String, ({int count, double total})>{};
    for (final sale in sales) {
      final clientName = sale.customerName ?? 'Client anonyme';
      if (!result.containsKey(clientName)) {
        result[clientName] = (count: 0, total: 0.0);
      }
      final current = result[clientName]!;
      result[clientName] = (
        count: current.count + sale.quantity,
        total: current.total + sale.totalAmount,
      );
    }
    return result;
  }
}

