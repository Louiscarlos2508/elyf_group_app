import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/collection.dart';
import '../../../domain/entities/tour.dart';
import 'client_selector.dart';

/// Handler pour la soumission du formulaire de collecte.
class CollectionSubmitHandler {
  CollectionSubmitHandler._();

  static Future<bool> submit({
    required BuildContext context,
    required WidgetRef ref,
    required Tour tour,
    required CollectionType collectionType,
    required Client selectedClient,
    required Map<int, int> bottles,
    required List<int> availableWeights,
  }) async {
    if (bottles.isEmpty) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un type de bouteille')),
      );
      return false;
    }

    try {
      final controller = ref.read(tourControllerProvider);
      final cylinders = await ref.read(cylindersProvider.future);

      double unitPrice = 0.0;
      final Map<int, double> unitPricesByWeight = {};

      // Pour les grossistes, utiliser le prix en gros des paramètres par poids
      if (collectionType == CollectionType.wholesaler) {
        if (cylinders.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aucune bouteille configurée. Veuillez d\'abord configurer les bouteilles dans les paramètres.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        }

        final settingsController = ref.read(gazSettingsControllerProvider);
        // Récupérer le prix en gros pour chaque poids de bouteille
        for (final weight in bottles.keys) {
          final wholesalePrice = await settingsController.getWholesalePrice(
            enterpriseId: tour.enterpriseId,
            moduleId: 'gaz',
            weight: weight,
          );
          if (wholesalePrice != null && wholesalePrice > 0) {
            unitPricesByWeight[weight] = wholesalePrice;
          } else {
            // Si pas de prix en gros configuré, utiliser le prix de vente
            final cylinder = cylinders.firstWhere(
              (c) => c.weight == weight,
              orElse: () => cylinders.first,
            );
            unitPricesByWeight[weight] = cylinder.sellPrice;
          }
        }
        // Prix par défaut (pour compatibilité) : utiliser le premier prix trouvé
        if (unitPricesByWeight.isNotEmpty) {
          unitPrice = unitPricesByWeight.values.first;
        } else if (cylinders.isNotEmpty) {
          unitPrice = cylinders.first.sellPrice;
        }
      } else {
        // Pour les points de vente, utiliser le prix de vente normal
        if (cylinders.isNotEmpty) {
          unitPrice = cylinders.first.sellPrice;
          // Pour les points de vente, utiliser le même prix pour tous les poids
          for (final weight in bottles.keys) {
            final cylinder = cylinders.firstWhere(
              (c) => c.weight == weight,
              orElse: () => cylinders.first,
            );
            unitPricesByWeight[weight] = cylinder.sellPrice;
          }
        }
      }

      final collection = Collection(
        id: 'collection_${DateTime.now().millisecondsSinceEpoch}',
        type: collectionType,
        clientId: selectedClient.id,
        clientName: selectedClient.name,
        clientPhone: selectedClient.phone,
        clientAddress: selectedClient.address,
        emptyBottles: bottles,
        unitPrice: unitPrice,
        unitPricesByWeight: unitPricesByWeight.isEmpty ? null : unitPricesByWeight,
      );

      final updatedCollections = [...tour.collections, collection];
      final updatedTour = tour.copyWith(collections: updatedCollections);

      await controller.updateTour(updatedTour);

      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}

