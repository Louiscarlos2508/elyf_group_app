import 'package:flutter/material.dart';

/// Widget affichant un état vide pour la liste des pointages.
class LiquidityEmptyState extends StatelessWidget {
  const LiquidityEmptyState({super.key, this.isRecent = false});

  final bool isRecent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 60,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isRecent ? 'Aucun pointage récent' : 'Aucun pointage trouvé',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isRecent
                  ? 'Il est temps de faire votre premier pointage pour assurer le suivi de votre caisse.'
                  : 'Aucun enregistrement ne correspond à vos critères de recherche actuels.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
