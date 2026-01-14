import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/gaz_button_styles.dart';

/// En-tête de l'écran des dépenses avec bouton d'ajout.
class ExpensesHeader extends StatelessWidget {
  const ExpensesHeader({
    super.key,
    required this.isMobile,
    required this.onNewExpense,
  });

  final bool isMobile;
  final VoidCallback onNewExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dépenses',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Suivi et gestion des dépenses par catégorie',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF6A7282),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onNewExpense,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nouvelle dépense'),
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
                        'Dépenses',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Suivi et gestion des dépenses par catégorie',
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
                    onPressed: onNewExpense,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nouvelle dépense'),
                    style: GazButtonStyles.filledPrimary,
                  ),
                ),
              ],
            ),
    );
  }
}
