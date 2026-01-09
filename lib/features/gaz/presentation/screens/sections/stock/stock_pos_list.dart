import 'package:flutter/material.dart';

import '../../../../domain/entities/cylinder_stock.dart';
import '../../../../domain/entities/point_of_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
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

        // Use calculation service for business logic
        final metrics = GazStockCalculationExtension.calculatePosStockMetrics(
          posId: pos.id,
          allStocks: allStocks,
        );

        return PointOfSaleStockCard(
          pointOfSale: pos,
          fullBottles: metrics.totalFull,
          emptyBottles: metrics.totalEmpty,
          stockByCapacity: metrics.stockByCapacity,
        );
      },
    );
  }
}

