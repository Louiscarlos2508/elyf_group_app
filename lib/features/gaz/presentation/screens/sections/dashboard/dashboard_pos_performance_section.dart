import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder.dart';
import '../../../../domain/entities/cylinder_stock.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../widgets/dashboard_point_of_sale_performance.dart';

/// Section de performance par point de vente pour le dashboard.
class DashboardPosPerformanceSection extends ConsumerWidget {
  const DashboardPosPerformanceSection({super.key, required this.sales});

  final List<GasSale> sales;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer l'entreprise active depuis le tenant provider
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null) {
          return const SizedBox.shrink();
        }
        
        final enterpriseId = enterprise.id;
        const moduleId = 'gaz';

        // Récupérer les points de vente depuis le provider
        final pointsOfSaleAsync = ref.watch(
          pointsOfSaleProvider((enterpriseId: enterpriseId, moduleId: moduleId)),
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

            // Récupérer tous les stocks pour calculer le stock par point de vente
            final allStocksAsync = ref.watch(
              cylinderStocksProvider((
                enterpriseId: enterpriseId,
                status: null, // Tous les statuts
                siteId: null,
              )),
            );

            return allStocksAsync.when(
              data: (allStocks) {
                for (final pos in pointsOfSale) {
                  // Note: Les points de vente sont maintenant des entreprises à part entière
                  // (avec parentEnterpriseId). Dans le futur, quand les ventes seront créées
                  // depuis un point de vente spécifique, elles auront l'enterpriseId du point
                  // de vente et pourront être filtrées directement.
                  // 
                  // Pour l'instant, distribuer équitablement les ventes au détail car
                  // les ventes sont créées avec l'enterpriseId de l'entreprise mère.
                  // TODO: Implémenter le filtrage par enterpriseId (point de vente) quand
                  // la création de vente depuis un point de vente sera disponible.
                  salesByPos[pos.id] = retailSales.isEmpty
                      ? 0.0
                      : (retailSales.fold<double>(0, (sum, s) => sum + s.totalAmount) /
                            pointsOfSale.length);
                  salesCountByPos[pos.id] = retailSales.isEmpty
                      ? 0
                      : (retailSales.length / pointsOfSale.length).round();
                  
                  // Récupérer le stock réel pour ce point de vente
                  final posStocks = allStocks
                      .where((s) => s.siteId == pos.id || 
                             (s.siteId == null && pos.isActive))
                      .where((s) => s.status == CylinderStatus.full)
                      .toList();
                  stockByPos[pos.id] = posStocks.fold<int>(
                    0,
                    (sum, s) => sum + s.quantity,
                  );
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
              error: (_, __) => DashboardPointOfSalePerformance(
                pointsOfSale: pointsOfSale,
                salesByPos: salesByPos,
                stockByPos: stockByPos,
                salesCountByPos: salesCountByPos,
              ),
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
      },
      loading: () => const SizedBox(
        height: 262,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
