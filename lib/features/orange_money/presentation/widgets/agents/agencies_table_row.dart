import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/orange_money_enterprise_extensions.dart';
import 'agents_format_helpers.dart';
import 'agents_table_cell.dart';
import 'agents_table_components.dart';

/// Ligne de tableau pour une agence.
class AgenciesTableRow extends StatelessWidget {
  const AgenciesTableRow({
    super.key,
    required this.agency,
    required this.onView,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  final Enterprise agency;
  final VoidCallback onView;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = agency.floatBalance ?? 0;
    final debt = agency.floatDebt ?? 0;
    
    return Container(
      height: 56, // Standard row height
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          AgentsTableComponents.buildAgentNameCell(agency),
          AgentsTableCell.buildCell(agency.phone ?? 'N/A', 122.274),
          AgentsTableCell.buildCell(agency.type.label, 100.0),
          AgentsTableCell.buildCell(
            AgentsFormatHelpers.formatCurrency(balance),
            110.0,
            alignRight: false,
            color: balance == 0 ? theme.colorScheme.error : null,
          ),
          AgentsTableCell.buildCell(
            AgentsFormatHelpers.formatCurrency(debt),
            110.0,
            alignRight: true,
            color: debt > 0 ? theme.colorScheme.error : null,
          ),
          AgentsTableCell.buildCell(
            AgentsTableComponents.buildStatusChip(agency.isActive),
            62.246,
          ),
          AgentsTableComponents.buildActionsCell(
            onView: onView,
            onRefresh: () {}, // Handled by Agent Account now, but keeping for signature until removed from constructor
            onEdit: onEdit,
            onDelete: onDelete,
            width: 185.92,
          ),
        ],
      ),
    );
  }
}
