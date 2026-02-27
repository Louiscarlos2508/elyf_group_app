import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';

/// Handler pour la soumission du formulaire de bouteille.
class CylinderSubmitHandler {
  CylinderSubmitHandler._();

  static Future<bool> submit({
    required BuildContext context,
    required WidgetRef ref,
    required int? selectedWeight,
    required String weightText,
    required String sellPriceText,
    required String wholesalePriceText,
    required String buyPriceText,
    String? initialFullStockText,
    String? initialEmptyStockText,
    required String? enterpriseId,
    required String? moduleId,
    required Cylinder? existingCylinder,
  }) async {
    if (selectedWeight == null || enterpriseId == null || moduleId == null) {
      if (context.mounted) {
        NotificationService.showError(
          context,
          'Veuillez remplir tous les champs requis',
        );
      }
      return false;
    }

    try {
      final controller = ref.read(cylinderControllerProvider);
      final stockController = ref.read(cylinderStockControllerProvider);
      final cylinderStockRepo = ref.read(cylinderStockRepositoryProvider);
      final settingsController = ref.read(gazSettingsControllerProvider);
      
      final weight = int.tryParse(weightText) ?? selectedWeight;
      final sellPrice = double.tryParse(sellPriceText) ?? 0.0;
      final wholesalePrice = double.tryParse(wholesalePriceText) ?? sellPrice;
      final buyPrice = double.tryParse(buyPriceText) ?? 0.0;
      const depositPrice = 0.0; // Plus de vente de bouteille, uniquement échange

      Cylinder cylinder;
      if (existingCylinder != null) {
        cylinder = existingCylinder.copyWith(
          weight: weight,
          buyPrice: buyPrice,
          sellPrice: sellPrice,
          depositPrice: depositPrice,
        );
      } else {
        cylinder = Cylinder(
          id: 'cyl-${DateTime.now().millisecondsSinceEpoch}',
          weight: weight,
          buyPrice: buyPrice,
          sellPrice: sellPrice,
          enterpriseId: enterpriseId,
          moduleId: moduleId,
          stock: 0,
          depositPrice: depositPrice,
        );
      }

      // 1. Sauvegarder la bouteille
      if (existingCylinder == null) {
        await controller.addCylinder(cylinder);
      } else {
        await controller.updateCylinder(cylinder);
      }

      // 2. Initialisation ou Mise à jour du stock (Bi-modal)
      final fullQuantity = int.tryParse(initialFullStockText ?? '0') ?? 0;
      final emptyQuantity = int.tryParse(initialEmptyStockText ?? '0') ?? 0;
      
      final dbStocks = await cylinderStockRepo.getAllForEnterprise(enterpriseId);
      final cylinderStocks = dbStocks.where((s) => s.cylinderId == cylinder.id && s.siteId == null).toList();

      // Gestion Stock Plein
      final fullStocks = cylinderStocks.where((s) => s.status == CylinderStatus.full).toList();
      if (fullStocks.isNotEmpty) {
        final existingFull = fullStocks.first;
        if (existingFull.quantity != fullQuantity) {
          await stockController.updateStock(existingFull.copyWith(
            quantity: fullQuantity,
            updatedAt: DateTime.now(),
          ));
        }
        // Supprimer les doublons accidentels pour forcer la source de vérité
        for (int i = 1; i < fullStocks.length; i++) {
          await stockController.updateStock(fullStocks[i].copyWith(quantity: 0, deletedAt: DateTime.now()));
        }
      } else if (fullQuantity > 0) {
        await stockController.addStock(CylinderStock(
          id: 'stock-full-${cylinder.id}-${DateTime.now().millisecondsSinceEpoch}',
          cylinderId: cylinder.id,
          weight: cylinder.weight,
          status: CylinderStatus.full,
          quantity: fullQuantity,
          enterpriseId: enterpriseId,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ));
      }

      // Gestion Stock Vide
      final emptyStocks = cylinderStocks.where((s) => s.status == CylinderStatus.emptyAtStore).toList();
      if (emptyStocks.isNotEmpty) {
        final existingEmpty = emptyStocks.first;
        if (existingEmpty.quantity != emptyQuantity) {
          await stockController.updateStock(existingEmpty.copyWith(
            quantity: emptyQuantity,
            updatedAt: DateTime.now(),
          ));
        }
        // Supprimer les doublons accidentels
        for (int i = 1; i < emptyStocks.length; i++) {
          await stockController.updateStock(emptyStocks[i].copyWith(quantity: 0, deletedAt: DateTime.now()));
        }
      } else if (emptyQuantity > 0) {
        await stockController.addStock(CylinderStock(
          id: 'stock-empty-${cylinder.id}-${DateTime.now().millisecondsSinceEpoch}',
          cylinderId: cylinder.id,
          weight: cylinder.weight,
          status: CylinderStatus.emptyAtStore,
          quantity: emptyQuantity,
          enterpriseId: enterpriseId,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
        ));
      }

      // 3. Mettre à jour les prix dans les paramètres (Settings) pour la cohérence globale
      await settingsController.setRetailPrice(
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        weight: weight,
        price: sellPrice,
      );
      
      await settingsController.setWholesalePrice(
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        weight: weight,
        price: wholesalePrice,
      );
      
      await settingsController.setPurchasePrice(
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        weight: weight,
        price: buyPrice,
      );

      if (!context.mounted) return false;

      // Invalider les providers pour forcer le rafraîchissement
      ref.invalidate(cylindersProvider);
      ref.invalidate(cylinderStocksProvider);

      Navigator.of(context).pop();

      if (context.mounted) {
        NotificationService.showSuccess(
          context,
          existingCylinder == null
              ? 'Bouteille créée avec succès'
              : 'Bouteille mise à jour',
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, e.toString());
      }
      return false;
    }
  }
}
