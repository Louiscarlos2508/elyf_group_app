import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../widgets/point_of_sale_stock_card.dart';

/// Liste des cartes de stock par point de vente.
class StockPosList extends ConsumerWidget {
  const StockPosList({
    super.key,
    required this.activePointsOfSale,
    required this.allStocks,
  });

  final List<Enterprise> activePointsOfSale;
  final List<CylinderStock> allStocks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cylinders = ref.watch(cylindersProvider).value ?? [];
    
    // Trier les points de vente par urgence de stock (moins de bouteilles pleines en premier)
    final sortedPos = [...activePointsOfSale];
    sortedPos.sort((a, b) {
      final metricsA = GazCalculationService.calculatePosStockMetrics(
        posId: a.id,
        allStocks: allStocks,
        cylinders: cylinders,
      );
      final metricsB = GazCalculationService.calculatePosStockMetrics(
        posId: b.id,
        allStocks: allStocks,
        cylinders: cylinders,
      );
      return metricsA.totalFull.compareTo(metricsB.totalFull);
    });

    return SliverList.separated(
      itemCount: sortedPos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final pos = sortedPos[index];

        // Use calculation service for business logic
        final metrics = GazCalculationService.calculatePosStockMetrics(
          posId: pos.id,
          allStocks: allStocks,
          cylinders: cylinders,
        );

        return PointOfSaleStockCard(
          enterprise: pos,
          fullBottles: metrics.totalFull,
          emptyBottles: metrics.totalEmpty,
          issueBottles: metrics.totalIssues,
          stockByCapacity: metrics.stockByCapacity,
        );
      },
    );
  }
}
