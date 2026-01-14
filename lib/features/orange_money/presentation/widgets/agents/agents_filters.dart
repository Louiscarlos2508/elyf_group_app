import 'package:flutter/material.dart';

import '../../../domain/entities/agent.dart';
import 'agents_name_filter.dart';
import 'agents_search_field.dart';
import 'agents_status_filter.dart';

/// Barre de filtres pour les agents.
class AgentsFilters extends StatelessWidget {
  const AgentsFilters({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onReset,
  });

  final String searchQuery;
  final AgentStatus? statusFilter;
  final String? sortBy;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AgentStatus?> onStatusChanged;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: AgentsSearchField(onChanged: onSearchChanged)),
        const SizedBox(width: 16),
        AgentsStatusFilter(value: statusFilter, onChanged: onStatusChanged),
        const SizedBox(width: 16),
        AgentsNameFilter(value: sortBy, onChanged: onSortChanged),
        const SizedBox(width: 16),
        SizedBox(
          width: 210.586,
          height: 36,
          child: OutlinedButton(
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1.219,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Réinitialiser',
              style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
            ),
          ),
        ),
      ],
    );
  }
}
