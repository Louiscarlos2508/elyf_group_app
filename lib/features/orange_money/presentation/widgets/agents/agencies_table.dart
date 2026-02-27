import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'agents_table_cell.dart';
import 'agencies_table_row.dart';

/// Tableau des agences.
class AgenciesTable extends StatelessWidget {
  const AgenciesTable({
    super.key,
    required this.agencies,
    required this.onView,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Enterprise> agencies;
  final void Function(Enterprise) onView;
  final void Function(Enterprise) onRefresh;
  final void Function(Enterprise) onEdit;
  final void Function(Enterprise) onDelete;

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
                height: 48, // Improved height for header
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
                    AgentsTableCell.buildHeader('Agence', 171.673),
                    AgentsTableCell.buildHeader('Téléphone', 122.274),
                    AgentsTableCell.buildHeader('Type', 100.0),
                    AgentsTableCell.buildHeader(
                      'Solde Cash',
                      110.0,
                      alignRight: false,
                    ),
                    AgentsTableCell.buildHeader(
                      'Dette OM',
                      110.0,
                      alignRight: true,
                    ),
                    AgentsTableCell.buildHeader('Statut', 62.246),
                    AgentsTableCell.buildHeader('Actions', 185.92),
                  ],
                ),
              ),
              // Table body
              if (agencies.isEmpty)
                Container(
                  width: 973, // Total width of all columns
                  height: 128,
                  alignment: Alignment.center,
                  child: Text(
                    'Aucune agence trouvée',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...agencies.map((agency) {
                  return AgenciesTableRow(
                    agency: agency,
                    onView: () => onView(agency),
                    onRefresh: () => onRefresh(agency),
                    onEdit: () => onEdit(agency),
                    onDelete: () => onDelete(agency),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
