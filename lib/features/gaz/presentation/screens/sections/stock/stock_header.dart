import 'package:flutter/material.dart';

import '../../../../../../shared/presentation/widgets/gaz_button_styles.dart';

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
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock des points de vente',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consultez et ajustez les stocks de bouteilles de chaque point de vente',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF6A7282),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAdjustStock,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajuster le stock'),
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
                        'Stock des points de vente',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Consultez et ajustez les stocks de bouteilles de chaque point de vente',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF6A7282),
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
                    style: GazButtonStyles.filledPrimary,
                  ),
                ),
              ],
            ),
    );
  }
}

