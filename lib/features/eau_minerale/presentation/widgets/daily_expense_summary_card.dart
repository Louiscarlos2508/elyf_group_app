import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import 'package:flutter/material.dart';

/// Daily expense summary card.
class DailyExpenseSummaryCard extends StatelessWidget {
  const DailyExpenseSummaryCard({
    super.key,
    required this.total,
    required this.formatCurrency,
  });

  final int total;
  final String Function(int) formatCurrency;



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElyfCard(
      isGlass: true,
      borderColor: Colors.red.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.trending_down_rounded,
              size: 28,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dépenses du Jour',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatCurrency(total)} CFA',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
