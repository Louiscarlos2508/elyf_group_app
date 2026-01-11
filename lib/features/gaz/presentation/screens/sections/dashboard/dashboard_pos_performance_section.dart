import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../widgets/dashboard_point_of_sale_performance.dart';

/// Section de performance par point de vente pour le dashboard.
class DashboardPosPerformanceSection extends ConsumerWidget {
  const DashboardPosPerformanceSection({
    super.key,
    required this.sales,
  });

  final List<GasSale> sales;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Récupérer enterpriseId et moduleId depuis le contexte/tenant
    // Utiliser les mêmes valeurs que dans les paramètres pour la cohérence
    const enterpriseId = 'gaz_1';
    const moduleId = 'gaz';

    // Récupérer les points de vente depuis le provider
    final pointsOfSaleAsync = ref.watch(
      pointsOfSaleProvider(
        (enterpriseId: enterpriseId, moduleId: moduleId),
      ),
    );

    return pointsOfSaleAsync.when(
      data: (pointsOfSale) {
        // Utiliser le service pour les calculs
        final todaySales = GazCalculationService.calculateTodaySales(sales);

        // Calculate sales and stock by POS
        // Note: Pour l'instant, on distribue les ventes équitablement car
        // les ventes ne sont pas encore associées à un point de vente spécifique.
        // Dans le futur, avec la gestion des utilisateurs par point de vente,
        // les ventes seront automatiquement associées au point de vente de l'utilisateur.
        final salesByPos = <String, double>{};
        final stockByPos = <String, int>{};
        final salesCountByPos = <String, int>{};

        // Filtrer uniquement les ventes au détail
        final retailSales = todaySales
            .where((s) => s.saleType == SaleType.retail)
            .toList();

        for (final pos in pointsOfSale) {
          // Pour l'instant, distribuer équitablement les ventes au détail
          // TODO: Quand les utilisateurs seront associés aux points de vente,
          // les ventes seront automatiquement filtrées par point de vente
          salesByPos[pos.id] = retailSales.isEmpty
              ? 0.0
              : (retailSales.fold<double>(0, (sum, s) => sum + s.totalAmount) /
                  pointsOfSale.length);
          salesCountByPos[pos.id] = retailSales.isEmpty
              ? 0
              : (retailSales.length / pointsOfSale.length).round();
          stockByPos[pos.id] = 0; // TODO: Get actual stock from CylinderStock
        }

        return DashboardPointOfSalePerformance(
          pointsOfSale: pointsOfSale,
          salesByPos: salesByPos,
          stockByPos: stockByPos,
          salesCountByPos: salesCountByPos,
        );
      },
      loading: () => const SizedBox(
        height: 262,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 8),
            Text(
              'Erreur de chargement',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

