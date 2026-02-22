import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../features/administration/domain/entities/enterprise.dart';

/// Widget displaying performance by point of sale for today.
class DashboardPointOfSalePerformance extends StatelessWidget {
  const DashboardPointOfSalePerformance({
    super.key,
    required this.pointsOfSale,
    required this.salesByPos,
    required this.stockByPos,
    this.salesCountByPos,
  });

  final List<Enterprise> pointsOfSale;
  final Map<String, double> salesByPos; // posId -> sales amount
  final Map<String, int> stockByPos; // posId -> stock count
  final Map<String, int>? salesCountByPos; // posId -> sales count

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElyfCard(
      isGlass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with icon
          Row(
            children: [
              Icon(
                Icons.store_rounded,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Performance par point de vente (aujourd'hui)",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // List of points of sale
          if (pointsOfSale.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 48,
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun point de vente enregistré',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pointsOfSale.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pos = pointsOfSale[index];
                final sales = salesByPos[pos.id] ?? 0.0;
                final stock = stockByPos[pos.id] ?? 0;
                final salesCount = salesCountByPos?[pos.id] ?? 0;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.store_rounded,
                          size: 22,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name and details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pos.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$salesCount vente(s) • $stock en stock',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Sales amount
                      Text(
                        CurrencyFormatter.formatDouble(sales),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF10B981),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
