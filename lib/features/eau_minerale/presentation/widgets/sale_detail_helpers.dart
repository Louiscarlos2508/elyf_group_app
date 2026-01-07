import 'package:flutter/material.dart';

import '../../../../shared.dart';
import '../../domain/entities/sale.dart';

/// Helper functions for sale detail display.
class SaleDetailHelpers {
  static String formatCurrency(int amount) {
    // Utiliser CurrencyFormatter mais avec " CFA" au lieu de " FCFA" pour compatibilité
    return CurrencyFormatter.formatFCFA(amount).replaceAll(' FCFA', ' CFA');
  }

  static String formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  static String getStatusLabel(SaleStatus status) {
    switch (status) {
      case SaleStatus.validated:
        return 'Validée';
      case SaleStatus.fullyPaid:
        return 'Payée';
    }
  }

  static Color getStatusColor(SaleStatus status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case SaleStatus.validated:
        return Colors.green;
      case SaleStatus.fullyPaid:
        return theme.colorScheme.primary;
    }
  }
}

/// Reusable detail row widget.
class SaleDetailRow extends StatelessWidget {
  const SaleDetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

