import 'package:flutter/material.dart';

import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/entities/point_of_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../widgets/dashboard_point_of_sale_performance.dart';

/// Section de performance par point de vente pour le dashboard.
class DashboardPosPerformanceSection extends StatelessWidget {
  const DashboardPosPerformanceSection({
    super.key,
    required this.sales,
  });

  final List<GasSale> sales;

  @override
  Widget build(BuildContext context) {
    // Mock points of sale for now
    final pointsOfSale = [
      PointOfSale(
        id: 'pos_1',
        name: 'Point de vente 1',
        address: '123 Rue de la Gaz',
        contact: '0123456789',
        enterpriseId: 'gaz_1',
        moduleId: 'gaz',
        isActive: true,
      ),
      PointOfSale(
        id: 'pos_2',
        name: 'Point de vente 2',
        address: '456 Rue de la Gaz',
        contact: '0987654321',
        enterpriseId: 'gaz_1',
        moduleId: 'gaz',
        isActive: true,
      ),
    ];

    // Utiliser le service pour les calculs
    final todaySales = GazCalculationService.calculateTodaySales(sales);

    // Calculate sales and stock by POS
    final salesByPos = <String, double>{};
    final stockByPos = <String, int>{};
    final salesCountByPos = <String, int>{};

    for (final pos in pointsOfSale) {
      // Note: GasSale doesn't have pointOfSaleId yet, so we'll distribute sales evenly
      // TODO: Add pointOfSaleId to GasSale entity and filter properly
      // For now, distribute sales evenly among POS
      salesByPos[pos.id] = todaySales.isEmpty
          ? 0.0
          : (todaySales.fold<double>(0, (sum, s) => sum + s.totalAmount) /
              pointsOfSale.length);
      salesCountByPos[pos.id] = todaySales.isEmpty
          ? 0
          : (todaySales.length / pointsOfSale.length).round();
      stockByPos[pos.id] = 0; // TODO: Get actual stock from CylinderStock
    }

    return DashboardPointOfSalePerformance(
      pointsOfSale: pointsOfSale,
      salesByPos: salesByPos,
      stockByPos: stockByPos,
      salesCountByPos: salesCountByPos,
    );
  }
}

