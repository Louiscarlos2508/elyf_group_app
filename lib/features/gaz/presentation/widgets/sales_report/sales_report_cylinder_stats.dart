import 'package:flutter/material.dart';

import '../../../../shared.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/gas_sale.dart';

/// Statistiques des ventes par type de bouteille.
class SalesReportCylinderStats extends StatelessWidget {
  const SalesReportCylinderStats({
    super.key,
    required this.sales,
    required this.cylinders,
  });

  final List<GasSale> sales;
  final List<Cylinder> cylinders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salesByCylinder = _groupSalesByCylinder(sales, cylinders);

    if (salesByCylinder.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Par Type de Bouteille',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...salesByCylinder.entries.map((entry) {
            final data = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
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
                        Icons.inventory_2,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${data.weight} kg',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
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
                        '${data.count} bouteille${data.count > 1 ? 's' : ''} vendue${data.count > 1 ? 's' : ''}',
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
      ),
    );
  }

  Map<String, ({int weight, int count, double total})> _groupSalesByCylinder(
    List<GasSale> sales,
    List<Cylinder> cylinders,
  ) {
    final result = <String, ({int weight, int count, double total})>{};

    for (final sale in sales) {
      final cylinder = cylinders.firstWhere(
        (c) => c.id == sale.cylinderId,
        orElse: () => cylinders.isNotEmpty
            ? cylinders.first
            : throw StateError('No cylinders'),
      );

      if (!result.containsKey(sale.cylinderId)) {
        result[sale.cylinderId] = (
          weight: cylinder.weight,
          count: 0,
          total: 0.0,
        );
      }
      final current = result[sale.cylinderId]!;
      result[sale.cylinderId] = (
        weight: current.weight,
        count: current.count + sale.quantity,
        total: current.total + sale.totalAmount,
      );
    }

    return result;
  }
}

