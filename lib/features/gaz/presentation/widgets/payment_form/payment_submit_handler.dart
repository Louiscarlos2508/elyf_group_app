import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../../../../core/errors/app_exceptions.dart';
import '../../../../../../core/errors/error_handler.dart';
import '../../../../../../core/logging/app_logger.dart';
import '../../../domain/entities/collection.dart';
import '../../../domain/entities/tour.dart';
import '../../../domain/services/collection_calculation_service.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';

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
      NotificationService.showError(
        context,
        'Le montant doit être supérieur à 0',
      );
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

      // Invalider les providers pour rafraîchir l'UI
      if (context.mounted) {
        developer.log(
          'Paiement enregistré, rafraîchissement des providers',
          name: 'PaymentSubmitHandler',
        );
        ref.invalidate(
          toursProvider((
            enterpriseId: tour.enterpriseId,
            status: null,
          )),
        );
        // Forcer le rechargement du tour en utilisant refresh
        ref.refresh(tourProvider(tour.id).future).ignore();
      }

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
                  : throw NotFoundException(
                      'Aucune bouteille trouvée pour le poids $weight kg',
                      'CYLINDER_NOT_FOUND',
                    ),
            );

            // Créer un enregistrement de fuite pour chaque bouteille
            for (int i = 0; i < leakQuantity; i++) {
              await leakController.reportLeak(
                cylinder.id,
                weight,
                tour.enterpriseId,
                tourId: tour.id,
                notes:
                    'Fuite signalée lors du paiement de la collecte ${collection.clientName}',
              );
            }
          }
        } catch (e) {
          // Logger l'erreur mais ne pas bloquer l'enregistrement du paiement
          AppLogger.error(
            'Erreur lors de la création des enregistrements de fuite: $e',
            name: 'gaz.payment',
            error: e,
          );
        }
      }

      if (!context.mounted) return false;

      Navigator.of(context).pop(true);
      NotificationService.showSuccess(
        context,
        'Paiement enregistré avec succès',
      );

      return true;
    } catch (e, stackTrace) {
      if (!context.mounted) return false;
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Erreur lors de l\'enregistrement du paiement: ${appException.message}',
        name: 'gaz.payment',
        error: e,
        stackTrace: stackTrace,
      );
      NotificationService.showError(
        context,
        ErrorHandler.instance.getUserMessage(appException),
      );
      return false;
    }
  }
}
