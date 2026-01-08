import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/gaz_button_styles.dart';

/// En-tête de l'écran de gestion des fuites.
class LeakHeader extends StatelessWidget {
  const LeakHeader({
    super.key,
    required this.isMobile,
    required this.onReportLeak,
  });

  final bool isMobile;
  final VoidCallback onReportLeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bouteilles avec Fuites',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérez les bouteilles avec fuites signalées',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF4A5565),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onReportLeak,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Signaler une fuite'),
                    style: GazButtonStyles.filledPrimary,
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
                        'Bouteilles avec Fuites',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gérez les bouteilles avec fuites signalées',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF4A5565),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: FilledButton.icon(
                    onPressed: onReportLeak,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Signaler une fuite'),
                    style: GazButtonStyles.filledPrimary,
                  ),
                ),
              ],
            ),
    );
  }
}

