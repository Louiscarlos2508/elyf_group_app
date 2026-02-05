import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../../../../core/logging/app_logger.dart';
import '../../../domain/entities/collection.dart';
import '../../../domain/entities/tour.dart';
import '../payment_form_dialog.dart';
import '../wholesaler_payment_card.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';

/// Contenu de l'étape retour du tour.
class ReturnStepContent extends ConsumerWidget {
  const ReturnStepContent({
    super.key,
    required this.tour,
    required this.enterpriseId,
  });

  final Tour tour;
  final String enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Filtrer les collections de type grossiste
    final wholesalerCollections = tour.collections
        .where((c) => c.type == CollectionType.wholesaler)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte principale
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1.305,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de la section
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: Color(0xFF0A0A0A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Encaissement et signalement des fuites',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF0A0A0A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Le client paie uniquement les bouteilles sans fuites. Les fuites seront réclamées au fournisseur.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF4A5565),
                ),
              ),
              const SizedBox(height: 16),
              // Liste des cartes de paiement pour chaque grossiste
              if (wholesalerCollections.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Aucun grossiste dans ce tour',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF6A7282),
                      ),
                    ),
                  ),
                )
              else
                ...wholesalerCollections.map((collection) {
                  return Padding(
                    key: ValueKey('payment_card_${collection.id}_${collection.amountPaid}'),
                    padding: const EdgeInsets.only(bottom: 16),
                    child: WholesalerPaymentCard(
                      collection: collection,
                      onPaymentPressed: () async {
                        try {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) => PaymentFormDialog(
                              tour: tour,
                              collection: collection,
                            ),
                          );
                          if (result == true && context.mounted) {
                            ref.invalidate(
                              toursProvider((
                                enterpriseId: enterpriseId,
                                status: null,
                              )),
                            );
                            // Forcer le rechargement du tour en utilisant refresh
                            await ref.refresh(tourProvider(tour.id).future);
                          }
                        } catch (e) {
                          AppLogger.error(
                            'Erreur lors du retour de bouteilles: $e',
                            name: 'gaz.tour',
                            error: e,
                          );
                          if (context.mounted) {
                            NotificationService.showError(
                              context,
                              'Erreur: $e',
                            );
                          }
                        }
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
