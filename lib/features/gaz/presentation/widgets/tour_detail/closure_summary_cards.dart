import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';

/// Cartes de résumé pour l'étape de clôture du tour fournisseur.
class ClosureSummaryCards extends StatelessWidget {
  const ClosureSummaryCards({
    super.key,
    required this.totalEmpty,
    required this.totalFull,
    required this.totalExpenses,
    required this.isMobile,
  });

  final int totalEmpty;
  final int totalFull;
  final double totalExpenses;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return isMobile
        ? Column(
            children: [
              _SummaryCard(
                title: 'Vides envoyés',
                value: '$totalEmpty',
                suffix: ' bouteilles',
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                title: 'Pleins reçus',
                value: '$totalFull',
                suffix: ' bouteilles',
                color: AppColors.success,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                title: 'Dépenses totales',
                value: CurrencyFormatter.formatDouble(totalExpenses),
                color: theme.colorScheme.error,
                theme: theme,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Vides envoyés',
                  value: '$totalEmpty',
                  suffix: ' btlles',
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Pleins reçus',
                  value: '$totalFull',
                  suffix: ' btlles',
                  color: AppColors.success,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Dépenses totales',
                  value: CurrencyFormatter.formatDouble(totalExpenses),
                  color: theme.colorScheme.error,
                  theme: theme,
                ),
              ),
            ],
          );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    this.suffix = '',
    required this.color,
    required this.theme,
  });

  final String title;
  final String value;
  final String suffix;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.05 : 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : theme.colorScheme.primary).withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (suffix.isNotEmpty)
                Text(
                  suffix,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
