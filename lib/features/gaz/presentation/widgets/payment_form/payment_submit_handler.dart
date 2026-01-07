import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/collection.dart';
import '../../../domain/entities/tour.dart';
import '../../../domain/services/collection_calculation_service.dart';
import '../../../../shared.dart';

/// Handler pour la soumission du formulaire de paiement.
class PaymentSubmitHandler {
  PaymentSubmitHandler._();

  static Future<bool> submit({
    required BuildContext context,
    required WidgetRef ref,
    required Tour tour,
    required Collection collection,
    required double amount,
    required Map<int, int> leaks,
  }) async {
    if (amount <= 0) {
      if (!context.mounted) return false;
      NotificationService.showError(context, 'Le montant doit être supérieur à 0');
      return false;
    }

    final newAmountDue = CollectionCalculationService.calculateAmountDue(
      collection,
      leaks,
    );

    if (amount > newAmountDue) {
      if (!context.mounted) return false;
      NotificationService.showError(
        context,
        'Le montant ne peut pas dépasser ${newAmountDue.toStringAsFixed(0)} FCFA',
      );
      return false;
    }

    try {
      final controller = ref.read(tourControllerProvider);
      final leakController = ref.read(cylinderLeakControllerProvider);

      // Mettre à jour la collecte avec les fuites et le nouveau paiement
      final updatedCollection = collection.copyWith(
        leaks: leaks,
        amountPaid: collection.amountPaid + amount,
        paymentDate: DateTime.now(),
      );

      // Mettre à jour le tour avec la collecte modifiée
      final updatedCollections = tour.collections.map((c) {
        return c.id == updatedCollection.id ? updatedCollection : c;
      }).toList();

      await controller.updateTour(
        tour.copyWith(collections: updatedCollections),
      );

      // Créer les enregistrements CylinderLeak pour chaque fuite signalée
      if (leaks.isNotEmpty) {
        try {
          // Récupérer tous les cylindres pour trouver les IDs par poids
          final cylinders = await ref.read(cylindersProvider.future);
          
          // Filtrer par entreprise
          final enterpriseCylinders = cylinders
              .where((c) => c.enterpriseId == tour.enterpriseId)
              .toList();

          // Pour chaque type de bouteille avec fuites
          for (final entry in leaks.entries) {
            final weight = entry.key;
            final leakQuantity = entry.value;

            if (leakQuantity <= 0) continue;

            // Trouver le cylindre correspondant au poids
            final cylinder = enterpriseCylinders.firstWhere(
              (c) => c.weight == weight,
              orElse: () => enterpriseCylinders.isNotEmpty
                  ? enterpriseCylinders.first
                  : throw Exception(
                      'Aucune bouteille trouvée pour le poids $weight kg',
                    ),
            );

            // Créer un enregistrement de fuite pour chaque bouteille
            for (int i = 0; i < leakQuantity; i++) {
              await leakController.reportLeak(
                cylinder.id,
                weight,
                tour.enterpriseId,
                tourId: tour.id,
                notes: 'Fuite signalée lors du paiement de la collecte ${collection.clientName}',
              );
            }
          }
        } catch (e) {
          // Logger l'erreur mais ne pas bloquer l'enregistrement du paiement
          debugPrint('Erreur lors de la création des enregistrements de fuite: $e');
        }
      }

      if (!context.mounted) return false;

      Navigator.of(context).pop(true);
      NotificationService.showSuccess(context, 'Paiement enregistré avec succès');

      return true;
    } catch (e) {
      if (!context.mounted) return false;
      NotificationService.showError(context, 'Erreur: $e');
      return false;
    }
  }
}

