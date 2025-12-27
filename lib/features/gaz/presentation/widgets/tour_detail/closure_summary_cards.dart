import 'package:flutter/material.dart';

import '../../../../../../shared/utils/currency_formatter.dart';

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
                color: const Color(0xFF00A63E),
                theme: theme,
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                title: 'Total dépenses',
                amount: totalExpenses,
                color: const Color(0xFFE7000B),
                theme: theme,
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                title: 'Bénéfice net',
                amount: netProfit,
                color: const Color(0xFF00A63E),
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
                  color: const Color(0xFF00A63E),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Total dépenses',
                  amount: totalExpenses,
                  color: const Color(0xFFE7000B),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Bénéfice net',
                  amount: netProfit,
                  color: const Color(0xFF00A63E),
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
      padding: const EdgeInsets.fromLTRB(25.285, 25.285, 1.305, 1.305),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.305,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: const Color(0xFF4A5565),
            ),
          ),
          const SizedBox(height: 42),
          Text(
            CurrencyFormatter.formatDouble(amount),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

