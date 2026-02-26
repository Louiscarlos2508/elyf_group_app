import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../widgets/point_of_sale_stock_card.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_stock_calculation_service.dart';

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
      final metricsA = GazStockCalculationService.calculatePosStockMetrics(
        enterpriseId: a.id,
        allStocks: allStocks,
        transfers: ref.read(stockTransfersProvider(a.id)).value,
        cylinders: cylinders,
      );
      final metricsB = GazStockCalculationService.calculatePosStockMetrics(
        enterpriseId: b.id,
        allStocks: allStocks,
        transfers: ref.read(stockTransfersProvider(b.id)).value,
        cylinders: cylinders,
      );
      return metricsA.totalFull.compareTo(metricsB.totalFull);
    });

    return SliverList.separated(
      itemCount: sortedPos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final pos = sortedPos[index];

        final transfers = ref.watch(stockTransfersProvider(pos.id)).value;

        // Use calculation service for business logic
        final metrics = GazStockCalculationService.calculatePosStockMetrics(
          enterpriseId: pos.id,
          allStocks: allStocks,
          transfers: transfers,
          cylinders: cylinders,
        );

        return PointOfSaleStockCard(
          enterprise: pos,
          fullBottles: metrics.totalFull,
          emptyBottles: metrics.totalEmpty,
          totalInTransit: metrics.totalInTransit,
          issueBottles: metrics.totalIssues,
          stockByCapacity: metrics.stockByCapacity,
        );
      },
    );
  }
}
