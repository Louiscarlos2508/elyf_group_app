import 'package:flutter/material.dart';

import '../../../../shared.dart';
import '../../domain/entities/point_of_sale.dart';

/// Widget displaying performance by point of sale for today.
class DashboardPointOfSalePerformance extends StatelessWidget {
  const DashboardPointOfSalePerformance({
    super.key,
    required this.pointsOfSale,
    required this.salesByPos,
    required this.stockByPos,
    this.salesCountByPos,
  });

  final List<PointOfSale> pointsOfSale;
  final Map<String, double> salesByPos; // posId -> sales amount
  final Map<String, int> stockByPos; // posId -> stock count
  final Map<String, int>? salesCountByPos; // posId -> sales count


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with icon
          Row(
            children: [
              Icon(
                Icons.store,
                size: 20,
                color: const Color(0xFF0A0A0A),
              ),
              const SizedBox(width: 8),
              Text(
                "Performance par point de vente (aujourd'hui)",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // List of points of sale
          if (pointsOfSale.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aucun point de vente',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...pointsOfSale.map((pos) {
              final sales = salesByPos[pos.id] ?? 0.0;
              final stock = stockByPos[pos.id] ?? 0;
              final salesCount = salesCountByPos?[pos.id] ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.3,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.store,
                        size: 20,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pos.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: const Color(0xFF101828),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$salesCount vente(s) • $stock bouteilles en stock',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF6A7282),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sales amount
                    Text(
                      CurrencyFormatter.formatDouble(sales),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF00A63E),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

