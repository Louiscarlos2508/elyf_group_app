import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import '../../../../domain/entities/gas_sale.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../../domain/entities/cylinder.dart';
import '../../../../domain/entities/cylinder_stock.dart';
import '../../../widgets/dashboard_point_of_sale_performance.dart';

/// Section de performance par point de vente pour le dashboard.
class DashboardPosPerformanceSection extends ConsumerWidget {
  const DashboardPosPerformanceSection({
    super.key,
    required this.sales,
    required this.stocks,
  });

  final List<GasSale> sales;
  final List<CylinderStock> stocks;

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
          enterprisesByParentAndTypeProvider((
            parentId: enterpriseId,
            type: EnterpriseType.gasPointOfSale,
          )),
        );

        return pointsOfSaleAsync.when(
          data: (pointsOfSale) {
            final salesByPos = <String, double>{};
            final stockByPos = <String, int>{};
            final salesCountByPos = <String, int>{};

            // Filtrer uniquement les ventes du jour
            final todaySales = GazCalculationService.calculateTodaySales(sales);

            for (final pos in pointsOfSale) {
              final posSales = todaySales.where((s) => s.enterpriseId == pos.id).toList();
              
              salesByPos[pos.id] = posSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
              salesCountByPos[pos.id] = posSales.length;
              
              // Stock plein pour ce POS
              stockByPos[pos.id] = stocks
                  .where((s) => s.enterpriseId == pos.id && s.status == CylinderStatus.full)
                  .fold<int>(0, (sum, s) => sum + s.quantity);
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
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              'Erreur de chargement',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ],
        ),
      ),
    );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => SizedBox(
        height: 200,
        child: Center(child: Text('Erreur: $error')),
      ),
    );
  }
}
