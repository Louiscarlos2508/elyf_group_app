import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:flutter/material.dart';

/// Gestionnaire de bouteilles pour le formulaire de collecte.
class BottleManager {
  BottleManager._();

  /// Ajoute une bouteille à la collection.
  static void addBottle({
    required BuildContext context,
    required int? selectedWeight,
    required String quantityText,
    required Map<int, int> bottles,
    required VoidCallback onBottlesChanged,
  }) {
    if (selectedWeight == null) {
      NotificationService.showWarning(
        context,
        'Sélectionnez un type de bouteille',
      );
      return;
    }

    final qty = int.tryParse(quantityText) ?? 0;
    if (qty <= 0) {
      NotificationService.showWarning(
        context,
        'La quantité doit être supérieure à 0',
      );
      return;
    }

    bottles[selectedWeight] = (bottles[selectedWeight] ?? 0) + qty;
    onBottlesChanged();
  }

  /// Retire une bouteille de la collection.
  static void removeBottle({
    required int weight,
    required Map<int, int> bottles,
    required VoidCallback onBottlesChanged,
  }) {
    bottles.remove(weight);
    onBottlesChanged();
  }
}
