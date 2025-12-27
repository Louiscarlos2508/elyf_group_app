import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
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

    // Group by weight for subtitle (6kg, 12kg, 38kg as per Figma)
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

    // Use available weights (6kg, 12kg shown in Figma, but we'll use system weights)
    final weightsToShow = [6, 12]; // Main weights shown in Figma
    final fullSubtitle = weightsToShow
        .map((w) => '${w}kg: ${fullByWeight[w] ?? 0}')
        .join(' • ');
    final emptySubtitle = weightsToShow
        .map((w) => '${w}kg: ${emptyByWeight[w] ?? 0}')
        .join(' • ');

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

