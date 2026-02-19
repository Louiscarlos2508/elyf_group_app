import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';

/// Cartes de résumé pour l'étape de clôture.
class ClosureSummaryCards extends StatelessWidget {
  const ClosureSummaryCards({
    super.key,
    required this.totalCollected,
    required this.totalExpenses,
    required this.netProfit,
    required this.isMobile,
  });

  final double totalCollected;
  final double totalExpenses;
  final double netProfit;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return isMobile
        ? Column(
            children: [
              _SummaryCard(
                title: 'Total encaissé',
                amount: totalCollected,
                color: AppColors.success,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                title: 'Total dépenses',
                amount: totalExpenses,
                color: theme.colorScheme.error,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                title: 'Bénéfice net',
                amount: netProfit,
                color: AppColors.success,
                theme: theme,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total encaissé',
                  amount: totalCollected,
                  color: AppColors.success,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Total dépenses',
                  amount: totalExpenses,
                  color: theme.colorScheme.error,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Bénéfice net',
                  amount: netProfit,
                  color: AppColors.success,
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
    required this.amount,
    required this.color,
    required this.theme,
  });

  final String title;
  final double amount;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
          const SizedBox(height: 42),
          Text(
            CurrencyFormatter.formatDouble(amount),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          ),
        ],
      ),
    );
  }
}
