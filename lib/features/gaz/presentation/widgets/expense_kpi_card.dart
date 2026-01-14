import 'package:flutter/material.dart';

/// KPI card for expenses - matches Figma design.
class ExpenseKpiCard extends StatelessWidget {
  const ExpenseKpiCard({
    super.key,
    required this.title,
    required this.amount,
    required this.count,
    required this.icon,
    this.amountColor,
  });

  final String title;
  final String amount;
  final String count;
  final IconData icon;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(1.3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF4A5565),
                  ),
                ),
                Icon(
                  icon,
                  size: 16,
                  color: amountColor ?? const Color(0xFFF54900),
                ),
              ],
            ),
          ),
          // Content with amount and count
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.normal,
                    color: amountColor ?? const Color(0xFFF54900),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF6A7282),
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
