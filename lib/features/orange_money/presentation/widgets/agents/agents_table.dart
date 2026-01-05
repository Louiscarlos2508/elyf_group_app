import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/agent.dart';
import 'agents_format_helpers.dart';
import 'agents_table_cell.dart';
import 'agents_table_row.dart';

/// Tableau des agents.
class AgentsTable extends StatelessWidget {
  const AgentsTable({
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
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.1),
                  width: 1.219,
                ),
              ),
            ),
            child: Row(
              children: [
                AgentsTableCell.buildHeader('Agent', 171.673),
                AgentsTableCell.buildHeader('Téléphone', 122.274),
                AgentsTableCell.buildHeader('N° SIM', 135.989),
                AgentsTableCell.buildHeader('Opérateur', 84.741),
                AgentsTableCell.buildHeader('Liquidité', 100.884, alignRight: false),
                AgentsTableCell.buildHeader('%Commission', 110.178, alignRight: true),
                AgentsTableCell.buildHeader('Statut', 62.246),
                AgentsTableCell.buildHeader('Actions', 185.92),
              ],
            ),
          ),
          // Table body
          if (agents.isEmpty)
            Container(
              height: 128,
              alignment: Alignment.center,
              child: Text(
                'Aucun agent trouvé',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6A7282),
                ),
              ),
            )
          else
            ...agents.map((agent) {
              return AgentsTableRow(
                agent: agent,
                onView: () => onView(agent),
                onRefresh: () => onRefresh(agent),
                onEdit: () => onEdit(agent),
                onDelete: () => onDelete(agent),
              );
            }).toList(),
        ],
      ),
    );
  }
}

