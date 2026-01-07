import 'package:flutter/material.dart';

import '../../../../shared.dart';

/// Item de dépense pour l'étape de clôture.
class ClosureExpenseItem extends StatelessWidget {
  const ClosureExpenseItem({
    super.key,
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  final String label;
  final double amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.fromLTRB(
        7.993,
        7.993,
        7.993,
        isTotal ? 1.305 : 0,
      ),
      decoration: BoxDecoration(
        color: isTotal ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
        border: isTotal
            ? Border.all(
                color: const Color(0xFFFFC9C9),
                width: 1.305,
              )
            : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: isTotal
                  ? const Color(0xFF82181A)
                  : const Color(0xFF364153),
            ),
          ),
          Text(
            CurrencyFormatter.formatDouble(amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: const Color(0xFFE7000B),
            ),
          ),
        ],
      ),
    );
  }
}

