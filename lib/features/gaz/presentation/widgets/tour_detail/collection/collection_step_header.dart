import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../core/logging/app_logger.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/tour.dart';
import '../../collection_form_dialog.dart';

/// En-tête de l'étape collecte.
class CollectionStepHeader extends ConsumerWidget {
  const CollectionStepHeader({
    super.key,
    required this.tour,
    required this.enterpriseId,
    this.onTourUpdated,
  });

  final Tour tour;
  final String enterpriseId;
  final VoidCallback? onTourUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.inventory_2, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Collecte des bouteilles vides',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          style: GazButtonStyles.filledPrimaryIcon(context),
          onPressed: () async {
            try {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => CollectionFormDialog(tour: tour),
              );
              if (result == true && context.mounted) {
                // Invalider les providers pour rafraîchir
                ref.invalidate(
                  toursProvider((enterpriseId: enterpriseId, status: null)),
                );
                // Invalider le provider du tour spécifique pour forcer le rafraîchissement
                ref.invalidate(tourProvider(tour.id));
                
                // Appeler le callback si disponible pour notifier le parent
                if (onTourUpdated != null) {
                  onTourUpdated!();
                }
              }
            } catch (e) {
              AppLogger.error(
                'Erreur lors de l\'ajout de collecte: $e',
                name: 'gaz.tour',
                error: e,
              );
              if (context.mounted) {
                NotificationService.showError(context, 'Erreur: $e');
              }
            }
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Ajouter', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
