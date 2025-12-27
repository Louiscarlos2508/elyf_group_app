import 'package:flutter/material.dart';

import '../../../../domain/entities/cylinder.dart';
import '../../../../domain/entities/cylinder_stock.dart';
import '../../../../domain/entities/point_of_sale.dart';
import '../../../widgets/point_of_sale_stock_card.dart';

/// Liste des cartes de stock par point de vente.
class StockPosList extends StatelessWidget {
  const StockPosList({
    super.key,
    required this.activePointsOfSale,
    required this.allStocks,
  });

  final List<PointOfSale> activePointsOfSale;
  final List<CylinderStock> allStocks;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: activePointsOfSale.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final pos = activePointsOfSale[index];

        // Get stocks for this POS (filter by siteId if available)
        final posStocks = allStocks
            .where((s) => s.siteId == pos.id || s.siteId == null)
            .toList();

        // Calculate full and empty for this POS
        final posFull = posStocks
            .where((s) => s.status == CylinderStatus.full)
            .fold<int>(0, (sum, s) => sum + s.quantity);
        final posEmpty = posStocks
            .where((s) =>
                s.status == CylinderStatus.emptyAtStore ||
                s.status == CylinderStatus.emptyInTransit)
            .fold<int>(0, (sum, s) => sum + s.quantity);

        // Group by capacity (use all available weights from system)
        final stockByCapacity = <int, ({int full, int empty})>{};
        // Get unique weights from posStocks
        final availableWeights = posStocks
            .map((s) => s.weight)
            .toSet()
            .toList()
          ..sort();
        for (final weight in availableWeights) {
          final full = posStocks
              .where((s) =>
                  s.weight == weight &&
                  s.status == CylinderStatus.full)
              .fold<int>(0, (sum, s) => sum + s.quantity);
          final empty = posStocks
              .where((s) =>
                  s.weight == weight &&
                  (s.status == CylinderStatus.emptyAtStore ||
                      s.status == CylinderStatus.emptyInTransit))
              .fold<int>(0, (sum, s) => sum + s.quantity);
          if (full > 0 || empty > 0) {
            stockByCapacity[weight] = (full: full, empty: empty);
          }
        }

        return PointOfSaleStockCard(
          pointOfSale: pos,
          fullBottles: posFull,
          emptyBottles: posEmpty,
          stockByCapacity: stockByCapacity,
        );
      },
    );
  }
}

