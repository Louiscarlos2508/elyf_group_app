import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/controllers/cylinder_controller.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder.dart';

/// Handler pour la soumission du formulaire de bouteille.
class CylinderSubmitHandler {
  CylinderSubmitHandler._();

  static Future<bool> submit({
    required BuildContext context,
    required WidgetRef ref,
    required int? selectedWeight,
    required String weightText,
    required String buyPriceText,
    required String sellPriceText,
    required String? enterpriseId,
    required String? moduleId,
    required Cylinder? existingCylinder,
  }) async {
    if (selectedWeight == null || enterpriseId == null || moduleId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez remplir tous les champs requis'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    try {
      final controller = ref.read(cylinderControllerProvider);
      final weight = int.tryParse(weightText) ?? selectedWeight;
      final buyPrice = double.tryParse(buyPriceText) ?? 0.0;
      final sellPrice = double.tryParse(sellPriceText) ?? 0.0;

      final cylinder = Cylinder(
        id: existingCylinder?.id ??
            'cyl-${DateTime.now().millisecondsSinceEpoch}',
        weight: weight,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      );

      if (existingCylinder == null) {
        await controller.addCylinder(cylinder);
      } else {
        await controller.updateCylinder(cylinder);
      }

      if (!context.mounted) return false;

      ref.invalidate(cylindersProvider);
      Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingCylinder == null
                  ? 'Bouteille créée avec succès'
                  : 'Bouteille mise à jour',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}

