import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder_stock.dart';
import '../../../../domain/entities/point_of_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../widgets/stock_kpi_card.dart';

/// Section des KPI cards pour le stock.
class StockKpiSection extends ConsumerWidget {
  const StockKpiSection({
    super.key,
    required this.allStocks,
    required this.activePointsOfSale,
    required this.pointsOfSale,
  });

  final List<CylinderStock> allStocks;
  final List<PointOfSale> activePointsOfSale;
  final List<PointOfSale> pointsOfSale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cylindersAsync = ref.watch(cylindersProvider);

    return cylindersAsync.when(
      data: (cylinders) {
        // Use calculation service for business logic
        final metrics = GazCalculationService.calculateStockMetrics(
          stocks: allStocks,
          pointsOfSale: pointsOfSale,
          cylinders: cylinders,
        );

        return _StockKpiCards(
          metrics: metrics,
          activePointsOfSaleCount: activePointsOfSale.length,
          totalPointsOfSaleCount: pointsOfSale.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) {
        // Fallback: use weights from stocks
        final allWeights = allStocks.map((s) => s.weight).toSet().toList()
          ..sort();
        final fullStocks = GazCalculationService.filterFullStocks(allStocks);
        final emptyStocks = GazCalculationService.filterEmptyStocks(allStocks);
        final fullByWeight = GazCalculationService.groupStocksByWeight(
          fullStocks,
        );
        final emptyByWeight = GazCalculationService.groupStocksByWeight(
          emptyStocks,
        );

        final metrics = StockMetrics(
          totalFull: fullStocks.fold<int>(0, (sum, s) => sum + s.quantity),
          totalEmpty: emptyStocks.fold<int>(0, (sum, s) => sum + s.quantity),
          fullByWeight: fullByWeight,
          emptyByWeight: emptyByWeight,
          activePointsOfSaleCount: activePointsOfSale.length,
          totalPointsOfSaleCount: pointsOfSale.length,
          availableWeights: allWeights,
        );

        return _StockKpiCards(
          metrics: metrics,
          activePointsOfSaleCount: activePointsOfSale.length,
          totalPointsOfSaleCount: pointsOfSale.length,
        );
      },
    );
  }
}

/// Widget privé pour afficher les KPI cards.
class _StockKpiCards extends StatelessWidget {
  const _StockKpiCards({
    required this.metrics,
    required this.activePointsOfSaleCount,
    required this.totalPointsOfSaleCount,
  });

  final StockMetrics metrics;
  final int activePointsOfSaleCount;
  final int totalPointsOfSaleCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: StockKpiCard(
                  title: 'Points de vente actifs',
                  value: '$activePointsOfSaleCount',
                  subtitle: 'sur $totalPointsOfSaleCount au total',
                  icon: Icons.store,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StockKpiCard(
                  title: 'Bouteilles pleines',
                  value: '${metrics.totalFull}',
                  subtitle: metrics.fullSummary,
                  icon: Icons.inventory_2,
                  valueColor: const Color(0xFF00A63E),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StockKpiCard(
                  title: 'Bouteilles vides',
                  value: '${metrics.totalEmpty}',
                  subtitle: metrics.emptySummary,
                  icon: Icons.inventory_2_outlined,
                  valueColor: const Color(0xFFF54900),
                ),
              ),
            ],
          );
        }

        // Mobile: stack vertically
        return Column(
          children: [
            StockKpiCard(
              title: 'Points de vente actifs',
              value: '$activePointsOfSaleCount',
              subtitle: 'sur $totalPointsOfSaleCount au total',
              icon: Icons.store,
            ),
            const SizedBox(height: 16),
            StockKpiCard(
              title: 'Bouteilles pleines',
              value: '${metrics.totalFull}',
              subtitle: metrics.fullSummary,
              icon: Icons.inventory_2,
              valueColor: const Color(0xFF00A63E),
            ),
            const SizedBox(height: 16),
            StockKpiCard(
              title: 'Bouteilles vides',
              value: '${metrics.totalEmpty}',
              subtitle: metrics.emptySummary,
              icon: Icons.inventory_2_outlined,
              valueColor: const Color(0xFFF54900),
            ),
          ],
        );
      },
    );
  }
}

