import 'package:flutter/material.dart';

/// Empty state widget when no expenses are recorded - matches Figma design.
class ExpensesEmptyState extends StatelessWidget {
  const ExpensesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: const Color(0xFF6A7282).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune dépense enregistrée',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF6A7282),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les dépenses enregistrées apparaîtront ici',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: const Color(0xFF99A1AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
