import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/services/gas_calculation_service.dart';
import '../../../domain/entities/cylinder.dart';

/// Gestionnaire de prix et stock pour le formulaire de vente.
class PriceStockManager {
  PriceStockManager._();

  /// Met à jour le prix unitaire selon le type de vente et le tier.
  static Future<double> updateUnitPrice({
    required WidgetRef ref,
    required Cylinder? cylinder,
    required String? enterpriseId,
    required bool isWholesale,
    String tier = 'default',
  }) async {
    if (cylinder == null || enterpriseId == null) {
      return 0.0;
    }

    // Pour les ventes en gros, utiliser le prix en gros des settings pour le tier choisi
    if (isWholesale) {
      try {
        final settings = await ref.read(gazSettingsRepositoryProvider(enterpriseId)).getSettings(
          enterpriseId: enterpriseId,
          moduleId: 'gaz',
        );
        
        return GasCalculationService.determineWholesalePrice(
          cylinder: cylinder,
          settings: settings,
          tier: tier,
        );
      } catch (e) {
        return cylinder.sellPrice;
      }
    } else {
      // Pour les ventes au détail, utiliser le prix de vente normal
      return cylinder.sellPrice;
    }
  }

  /// Met à jour le stock disponible.
  static Future<int> updateAvailableStock({
    required WidgetRef ref,
    required Cylinder? cylinder,
    required String? enterpriseId,
  }) async {
    if (cylinder == null || enterpriseId == null) {
      return 0;
    }

    try {
      final controller = ref.read(cylinderStockControllerProvider);
      return await controller.getAvailableStock(enterpriseId, cylinder.weight);
    } catch (e) {
      return 0;
    }
  }
}
