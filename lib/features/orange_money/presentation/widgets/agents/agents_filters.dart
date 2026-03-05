import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/features/orange_money/domain/entities/agent.dart' show AgentStatus;
import 'agents_name_filter.dart';
import 'agents_search_field.dart';
import 'agents_status_filter.dart';

/// Barre de filtres pour les agents.
class AgentsFilters extends StatelessWidget {
  final String searchQuery;
  final AgentStatus? statusFilter;
  final String? sortBy;
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AgentStatus?> onStatusChanged;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onDateRangeSelected;
  final VoidCallback onReset;

  const AgentsFilters({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.sortBy,
    required this.startDate,
    required this.endDate,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onDateRangeSelected,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search field - take full width on mobile, or 300 on tablet+
        SizedBox(
          width: MediaQuery.of(context).size.width < 600 ? double.infinity : 300,
          child: AgentsSearchField(onChanged: onSearchChanged),
        ),
        AgentsStatusFilter(value: statusFilter, onChanged: onStatusChanged),
        AgentsNameFilter(value: sortBy, onChanged: onSortChanged),
        
        // Date Range Picker Button
        OutlinedButton.icon(
          onPressed: onDateRangeSelected,
          icon: const Icon(Icons.calendar_today_rounded, size: 18),
          label: Text(
            '${DateFormat('dd/MM/yy').format(startDate)} - ${DateFormat('dd/MM/yy').format(endDate)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        SizedBox(
          height: 44, // Taller button for easier touch
          child: OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réinitialiser'),
            style: OutlinedButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              foregroundColor: theme.colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
