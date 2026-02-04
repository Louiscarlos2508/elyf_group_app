import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/gaz_button_styles.dart';

/// En-tête de l'écran d'approvisionnement avec bouton d'ajout.
class ApprovisionnementHeader extends StatelessWidget {
  const ApprovisionnementHeader({
    super.key,
    required this.isMobile,
    required this.onNewTour,
  });

  final bool isMobile;
  final VoidCallback onNewTour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tours d\'approvisionnement',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestion des cycles de collecte et rechargement',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onNewTour,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nouveau tour'),
                    style: GazButtonStyles.filledPrimary(context),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tours d\'approvisionnement',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestion des cycles de collecte et rechargement des bouteilles',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: FilledButton.icon(
                    onPressed: onNewTour,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nouveau tour'),
                    style: GazButtonStyles.filledPrimary(context),
                  ),
                ),
              ],
            ),
    );
  }
}
