import 'package:flutter/material.dart';

import '../../domain/entities/transaction.dart';

/// Widget for selecting transaction type (Cash-In or Cash-Out).
class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              context,
              TransactionType.cashIn,
              'Dépôt',
              Icons.south_west_rounded,
              const Color(0xFF00A63E), // Standard Success Green
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTypeButton(
              context,
              TransactionType.cashOut,
              'Retrait',
              Icons.north_east_rounded,
              const Color(0xFFE7000B), // Standard Error Red
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context,
    TransactionType type,
    String label,
    IconData icon,
    Color activeColor,
  ) {
    final theme = Theme.of(context);
    final isActive = selectedType == type;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return InkWell(
      onTap: () => onTypeChanged(type),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: isKeyboardOpen ? 10 : 12,
          horizontal: 12
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor : theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
              size: isKeyboardOpen ? 18 : 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: (isKeyboardOpen ? theme.textTheme.bodyMedium : theme.textTheme.titleMedium)?.copyWith(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
