import 'package:flutter/material.dart';

import '../../domain/entities/sale.dart';

/// Helper widgets for sales table.
class SalesTableHelpers {
  static Widget buildStatusChip(BuildContext context, Sale sale) {
    final theme = Theme.of(context);
    final isPaid = sale.isFullyPaid;
    final isCredit = sale.isCredit;
    
    String statusText;
    Color statusColor;
    
    if (isPaid) {
      statusText = 'Payé';
      statusColor = Colors.green;
    } else if (isCredit) {
      statusText = 'Crédit';
      statusColor = Colors.orange;
    } else {
      statusText = 'En attente';
      statusColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget buildActionButtons(
    BuildContext context,
    Sale sale,
    void Function(Sale sale, String action)? onActionTap,
  ) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility, size: 18),
            onPressed: () => onActionTap?.call(sale, 'view'),
            tooltip: 'Voir',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => onActionTap?.call(sale, 'edit'),
            tooltip: 'Modifier',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

