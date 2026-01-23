import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../../shared/presentation/widgets/gaz_button_styles.dart';
import '../../../../application/providers.dart';
import '../../../../domain/entities/tour.dart';
import '../../transport_expense_form_dialog.dart';

/// En-tête de l'étape transport.
class TransportStepHeader extends ConsumerWidget {
  const TransportStepHeader({
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
            const Icon(
              Icons.account_balance_wallet,
              size: 20,
              color: Color(0xFF0A0A0A),
            ),
            const SizedBox(width: 8),
            Text(
              'Frais de transport',
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
                builder: (context) => TransportExpenseFormDialog(tour: tour),
              );
              if (result == true && context.mounted) {
                ref.invalidate(
                  toursProvider((enterpriseId: enterpriseId, status: null)),
                );
                // Invalider le provider du tour pour forcer le rafraîchissement
                ref.refresh(tourProvider(tour.id));
              }
            } catch (e) {
              AppLogger.error(
                'Erreur lors de l\'ajout de dépense de transport: $e',
                name: 'gaz.tour',
                error: e,
              );
            }
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Ajouter dépense', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
