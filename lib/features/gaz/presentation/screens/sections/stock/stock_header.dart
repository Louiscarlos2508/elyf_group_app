import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/gaz_button_styles.dart';

/// En-tête de l'écran de stock.
class StockHeader extends StatelessWidget {
  const StockHeader({
    super.key,
    required this.isMobile,
    required this.onAdjustStock,
  });

  final bool isMobile;
  final VoidCallback onAdjustStock;

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
                  'Stock des points de vente',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consultez et ajustez les stocks de bouteilles de chaque point de vente',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAdjustStock,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajuster le stock'),
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
                        'Stock des points de vente',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Consultez et ajustez les stocks de bouteilles de chaque point de vente',
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
                    onPressed: onAdjustStock,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajuster le stock'),
                    style: GazButtonStyles.filledPrimary(context),
                  ),
                ),
              ],
            ),
    );
  }
}
