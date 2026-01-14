import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/tour.dart';
import '../../collection_form_dialog.dart';

/// En-tête de l'étape collecte.
class CollectionStepHeader extends ConsumerWidget {
  const CollectionStepHeader({
    super.key,
    required this.tour,
    required this.enterpriseId,
  });

  final Tour tour;
  final String enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2, size: 20, color: Color(0xFF0A0A0A)),
            const SizedBox(width: 8),
            Text(
              'Collecte des bouteilles vides',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF0A0A0A),
              ),
            ),
          ],
        ),
        FilledButton.icon(
          style: GazButtonStyles.filledPrimaryIcon,
          onPressed: () async {
            try {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => CollectionFormDialog(tour: tour),
              );
              if (result == true) {
                ref.invalidate(
                  toursProvider((enterpriseId: enterpriseId, status: null)),
                );
              }
            } catch (e) {
              debugPrint('Erreur: $e');
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
