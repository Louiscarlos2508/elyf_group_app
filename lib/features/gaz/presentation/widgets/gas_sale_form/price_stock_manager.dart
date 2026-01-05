import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/cylinder.dart';

/// Gestionnaire de prix et stock pour le formulaire de vente.
class PriceStockManager {
  PriceStockManager._();

  /// Met à jour le prix unitaire selon le type de vente.
  static Future<double> updateUnitPrice({
    required WidgetRef ref,
    required Cylinder? cylinder,
    required String? enterpriseId,
    required bool isWholesale,
  }) async {
    if (cylinder == null || enterpriseId == null) {
      return 0.0;
    }

    // Pour les ventes en gros, utiliser le prix en gros des settings
    if (isWholesale) {
      try {
        final settingsController = ref.read(gazSettingsControllerProvider);
        final wholesalePrice = await settingsController.getWholesalePrice(
          enterpriseId: enterpriseId,
          moduleId: 'gaz',
          weight: cylinder.weight,
        );
        return wholesalePrice ?? cylinder.sellPrice;
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
      return await controller.getAvailableStock(
        enterpriseId,
        cylinder.weight,
      );
    } catch (e) {
      return 0;
    }
  }
}

