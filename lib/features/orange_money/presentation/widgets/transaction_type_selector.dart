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
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFFFD6A7), // Orange border from design
          width: 1.219,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              context,
              TransactionType.cashIn,
              'Dépôt',
              Icons.arrow_downward,
              const Color(0xFF00A63E), // Green from design
              true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTypeButton(
              context,
              TransactionType.cashOut,
              'Retrait',
              Icons.arrow_upward,
              theme.colorScheme.onSurface,
              false,
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
    Color color,
    bool isSelected,
  ) {
    final isActive = selectedType == type;
    // Couleurs selon Figma: vert pour Dépôt sélectionné, rouge pour Retrait sélectionné
    final backgroundColor = isActive
        ? (type == TransactionType.cashIn
              ? const Color(0xFF00A63E) // Vert pour Dépôt
              : const Color(0xFFE7000B)) // Rouge pour Retrait
        : Colors.white;
    final textColor = isActive ? Colors.white : const Color(0xFF0A0A0A);
    final borderColor = isActive
        ? (type == TransactionType.cashIn
              ? const Color(0xFF00A63E)
              : const Color(0xFFE7000B))
        : const Color(0xFFE5E5E5);
    final iconColor = isActive ? Colors.white : const Color(0xFF0A0A0A);

    return InkWell(
      onTap: () => onTypeChanged(type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.219),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
