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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un type de bouteille')),
      );
      return;
    }

    final qty = int.tryParse(quantityText) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La quantité doit être supérieure à 0')),
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

