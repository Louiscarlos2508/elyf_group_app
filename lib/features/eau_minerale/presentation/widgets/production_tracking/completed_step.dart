import 'package:flutter/material.dart';

import '../../../../../app/theme/app_theme.dart';
import '../../../domain/entities/production_session.dart';
import 'info_row.dart';

/// Widget pour l'étape "Completed" (terminée) de la session de production.
class CompletedStep extends StatelessWidget {
  const CompletedStep({super.key, required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = Theme.of(context).extension<StatusColors>();

    return Card(
      color: statusColors?.success.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: statusColors?.success ?? theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Production terminée',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InfoRow(
              icon: Icons.inventory_2,
              label: 'Quantité produite',
              value:
                  '${session.quantiteProduite} packs',
            ),
            InfoRow(
              icon: Icons.access_time,
              label: 'Durée',
              value: '${session.dureeHeures.toStringAsFixed(1)} heures',
            ),
          ],
        ),
      ),
    );
  }
}
