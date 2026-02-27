import 'package:flutter/material.dart';

import '../../../domain/entities/agent.dart';
import 'agents_table_cell.dart';
import 'agent_account_table_row.dart';

/// Tableau des comptes agents (SIMs).
class AgentAccountTable extends StatelessWidget {
  const AgentAccountTable({
    super.key,
    required this.agents,
    required this.onView,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Agent> agents;
  final void Function(Agent) onView;
  final void Function(Agent) onRefresh;
  final void Function(Agent) onEdit;
  final void Function(Agent) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table header
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    AgentsTableCell.buildHeader('Agent', 171.673),
                    AgentsTableCell.buildHeader('Téléphone', 122.274),
                    AgentsTableCell.buildHeader('N° SIM', 135.989),
                    AgentsTableCell.buildHeader('Opérateur', 84.741),
                    AgentsTableCell.buildHeader(
                      'Liquidité SIM',
                      100.884,
                      alignRight: false,
                    ),
                    AgentsTableCell.buildHeader(
                      '%Commission',
                      110.178,
                      alignRight: true,
                    ),
                    AgentsTableCell.buildHeader('Statut', 62.246),
                    AgentsTableCell.buildHeader('Actions', 185.92),
                  ],
                ),
              ),
              // Table body
              if (agents.isEmpty)
                Container(
                  width: 973,
                  height: 128,
                  alignment: Alignment.center,
                  child: Text(
                    'Aucun compte agent trouvé',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...agents.map((agent) {
                  return AgentAccountTableRow(
                    agent: agent,
                    onView: () => onView(agent),
                    onRefresh: () => onRefresh(agent),
                    onEdit: () => onEdit(agent),
                    onDelete: () => onDelete(agent),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
