import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/shared.dart';
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
    required String? enterpriseId,
    required String? moduleId,
    required Cylinder? existingCylinder,
  }) async {
    if (selectedWeight == null || enterpriseId == null || moduleId == null) {
      if (context.mounted) {
        NotificationService.showError(context, 'Veuillez remplir tous les champs requis');
      }
      return false;
    }

    try {
      final controller = ref.read(cylinderControllerProvider);
      final weight = int.tryParse(weightText) ?? selectedWeight;
      final sellPrice = double.tryParse(sellPriceText) ?? 0.0;

      final cylinder = Cylinder(
        id: existingCylinder?.id ??
            'cyl-${DateTime.now().millisecondsSinceEpoch}',
        weight: weight,
        buyPrice: 0.0, // Prix d'achat non utilisé, mis à 0
        sellPrice: sellPrice,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      if (existingCylinder == null) {
        await controller.addCylinder(cylinder);
      } else {
        await controller.updateCylinder(cylinder);
      }

      // Sauvegarder ou supprimer le prix en gros
      final settingsController = ref.read(gazSettingsControllerProvider);
      if (wholesalePriceText.isNotEmpty) {
        final wholesalePrice = double.tryParse(wholesalePriceText);
        if (wholesalePrice != null && wholesalePrice > 0) {
          await settingsController.setWholesalePrice(
            enterpriseId: enterpriseId,
            moduleId: moduleId,
            weight: weight,
            price: wholesalePrice,
          );
        }
      } else {
        // Supprimer le prix en gros si le champ est vide
        await settingsController.removeWholesalePrice(
          enterpriseId: enterpriseId,
          moduleId: moduleId,
          weight: weight,
        );
      }

      if (!context.mounted) return false;

      // Invalider les providers pour forcer le rafraîchissement
      ref.invalidate(cylindersProvider);
      
      // Invalider le provider spécifique avec les bons paramètres
      ref.invalidate(
        gazSettingsProvider(
          (enterpriseId: enterpriseId, moduleId: moduleId),
        ),
      );
          Navigator.of(context).pop();

      if (context.mounted) {
        NotificationService.showSuccess(context, 
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

