import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder.dart';
import '../../../../domain/entities/cylinder_stock.dart';
import '../../../../domain/entities/point_of_sale.dart';
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
    // Récupérer les poids disponibles depuis les bouteilles créées
    final cylindersAsync = ref.watch(cylindersProvider);
    
    // Calculate totals
    final fullStocks = allStocks
        .where((s) => s.status == CylinderStatus.full)
        .toList();
    final emptyStocks = allStocks
        .where((s) =>
            s.status == CylinderStatus.emptyAtStore ||
            s.status == CylinderStatus.emptyInTransit)
        .toList();

    final totalFull = fullStocks.fold<int>(
      0,
      (sum, s) => sum + s.quantity,
    );
    final totalEmpty = emptyStocks.fold<int>(
      0,
      (sum, s) => sum + s.quantity,
    );

    // Group by weight for subtitle
    final fullByWeight = <int, int>{};
    final emptyByWeight = <int, int>{};
    for (final stock in fullStocks) {
      fullByWeight[stock.weight] =
          (fullByWeight[stock.weight] ?? 0) + stock.quantity;
    }
    for (final stock in emptyStocks) {
      emptyByWeight[stock.weight] =
          (emptyByWeight[stock.weight] ?? 0) + stock.quantity;
    }

    // Utiliser les poids dynamiques des bouteilles créées
    return cylindersAsync.when(
      data: (cylinders) {
        // Extraire les poids uniques des bouteilles existantes et les trier
        final weightsToShow = cylinders
            .map((c) => c.weight)
            .toSet()
            .toList()
          ..sort();
        
        final fullSubtitle = weightsToShow.isEmpty
            ? 'Aucune bouteille'
            : weightsToShow
                .map((w) => '${w}kg: ${fullByWeight[w] ?? 0}')
                .join(' • ');
        final emptySubtitle = weightsToShow.isEmpty
            ? 'Aucune bouteille'
            : weightsToShow
                .map((w) => '${w}kg: ${emptyByWeight[w] ?? 0}')
                .join(' • ');

        return _buildKpiCards(
          context: context,
          activePointsOfSale: activePointsOfSale,
          pointsOfSale: pointsOfSale,
          totalFull: totalFull,
          totalEmpty: totalEmpty,
          fullSubtitle: fullSubtitle,
          emptySubtitle: emptySubtitle,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) {
        // En cas d'erreur, utiliser tous les poids présents dans les stocks
        final allWeights = <int>{};
        for (final stock in allStocks) {
          allWeights.add(stock.weight);
        }
        final weightsToShow = allWeights.toList()..sort();
        
        final fullSubtitle = weightsToShow.isEmpty
            ? 'Aucune bouteille'
            : weightsToShow
                .map((w) => '${w}kg: ${fullByWeight[w] ?? 0}')
                .join(' • ');
        final emptySubtitle = weightsToShow.isEmpty
            ? 'Aucune bouteille'
            : weightsToShow
                .map((w) => '${w}kg: ${emptyByWeight[w] ?? 0}')
                .join(' • ');

        return _buildKpiCards(
          context: context,
          activePointsOfSale: activePointsOfSale,
          pointsOfSale: pointsOfSale,
          totalFull: totalFull,
          totalEmpty: totalEmpty,
          fullSubtitle: fullSubtitle,
          emptySubtitle: emptySubtitle,
        );
      },
    );
  }

  Widget _buildKpiCards({
    required BuildContext context,
    required List<PointOfSale> activePointsOfSale,
    required List<PointOfSale> pointsOfSale,
    required int totalFull,
    required int totalEmpty,
    required String fullSubtitle,
    required String emptySubtitle,
  }) {

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: StockKpiCard(
                  title: 'Points de vente actifs',
                  value: '${activePointsOfSale.length}',
                  subtitle: 'sur ${pointsOfSale.length} au total',
                  icon: Icons.store,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StockKpiCard(
                  title: 'Bouteilles pleines',
                  value: '$totalFull',
                  subtitle: fullSubtitle,
                  icon: Icons.inventory_2,
                  valueColor: const Color(0xFF00A63E),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StockKpiCard(
                  title: 'Bouteilles vides',
                  value: '$totalEmpty',
                  subtitle: emptySubtitle,
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
              value: '${activePointsOfSale.length}',
              subtitle: 'sur ${pointsOfSale.length} au total',
              icon: Icons.store,
            ),
            const SizedBox(height: 16),
            StockKpiCard(
              title: 'Bouteilles pleines',
              value: '$totalFull',
              subtitle: fullSubtitle,
              icon: Icons.inventory_2,
              valueColor: const Color(0xFF00A63E),
            ),
            const SizedBox(height: 16),
            StockKpiCard(
              title: 'Bouteilles vides',
              value: '$totalEmpty',
              subtitle: emptySubtitle,
              icon: Icons.inventory_2_outlined,
              valueColor: const Color(0xFFF54900),
            ),
          ],
        );
      },
    );
  }
}

