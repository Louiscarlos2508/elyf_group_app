import 'package:flutter/material.dart';

import '../../../domain/entities/agent.dart';
import 'agents_format_helpers.dart';
import 'agents_table_cell.dart';
import 'agents_table_components.dart';

/// Ligne de tableau pour un agent.
class AgentsTableRow extends StatelessWidget {
  const AgentsTableRow({
    super.key,
    required this.agent,
    required this.onView,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  final Agent agent;
  final VoidCallback onView;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
          AgentsTableComponents.buildAgentNameCell(agent),
          AgentsTableCell.buildCell(agent.phoneNumber, 122.274),
          AgentsTableCell.buildCell(agent.simNumber, 135.989),
          AgentsTableCell.buildCell(
            AgentsTableComponents.buildOperatorBadge(agent.operator),
            84.741,
          ),
          AgentsTableCell.buildCell(
            AgentsFormatHelpers.formatCurrency(agent.liquidity),
            100.884,
            alignRight: false,
            color: agent.liquidity == 0 ? const Color(0xFFE7000B) : null,
          ),
          AgentsTableCell.buildCell(
            '${agent.commissionRate}%',
            110.178,
            alignRight: true,
          ),
          AgentsTableCell.buildCell(
            AgentsTableComponents.buildStatusChip(agent.status),
            62.246,
          ),
          AgentsTableComponents.buildActionsCell(
            onView: onView,
            onRefresh: onRefresh,
            onEdit: onEdit,
            onDelete: onDelete,
            width: 185.92,
          ),
        ],
      ),
    );
  }
}
