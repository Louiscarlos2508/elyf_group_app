import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
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
  final List<Enterprise> activePointsOfSale;
  final List<Enterprise> pointsOfSale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cylindersAsync = ref.watch(cylindersProvider);
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final settingsAsync = ref.watch(gazSettingsProvider((
      enterpriseId: enterpriseId,
      moduleId: 'gaz',
    )));

    return cylindersAsync.when(
      data: (cylinders) {
        final viewType = ref.watch(gazDashboardViewTypeProvider);
        
        // Use calculation service for business logic
        final metrics = GazCalculationService.calculateStockMetrics(
          stocks: allStocks,
          pointsOfSale: pointsOfSale,
          cylinders: cylinders,
          settings: viewType == GazDashboardViewType.local ? settingsAsync.value : null,
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

        final viewType = ref.watch(gazDashboardViewTypeProvider);
        final settings = settingsAsync.value;
        if (viewType == GazDashboardViewType.local && settings != null && settings.nominalStocks.isNotEmpty) {
          for (final weight in allWeights) {
            final nominal = settings.getNominalStock(weight);
            if (nominal > 0) {
              final full = fullByWeight[weight] ?? 0;
              emptyByWeight[weight] = (nominal - full).clamp(0, nominal);
            }
          }
        }

        final totalFull = fullByWeight.values.fold<int>(0, (sum, val) => sum + val);
        final totalEmpty = emptyByWeight.values.fold<int>(0, (sum, val) => sum + val);

        final metrics = StockMetrics(
          totalFull: totalFull,
          totalEmpty: totalEmpty,
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
