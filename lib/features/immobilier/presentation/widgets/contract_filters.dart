import 'package:flutter/material.dart';

import '../../domain/entities/contract.dart';

/// Widget pour les filtres de contrats.
class ContractFilters extends StatelessWidget {
  const ContractFilters({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onClear,
  });

  final ContractStatus? selectedStatus;
  final ValueChanged<ContractStatus?> onStatusChanged;
  final VoidCallback onClear;

  String _getStatusLabel(ContractStatus status) {
    switch (status) {
      case ContractStatus.active:
        return 'Actif';
      case ContractStatus.expired:
        return 'Expiré';
      case ContractStatus.terminated:
        return 'Résilié';
      case ContractStatus.pending:
        return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilter = selectedStatus != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  PopupMenuButton<ContractStatus?>(
                    initialValue: selectedStatus,
                    onSelected: onStatusChanged,
                    itemBuilder: (context) => [
                      const PopupMenuItem<ContractStatus?>(
                        value: null,
                        child: Text('Tous les statuts'),
                      ),
                      ...ContractStatus.values.map(
                        (status) => PopupMenuItem<ContractStatus?>(
                          value: status,
                          child: Text(_getStatusLabel(status)),
                        ),
                      ),
                    ],
                    child: Chip(
                      label: Text(
                        selectedStatus != null
                            ? _getStatusLabel(selectedStatus!)
                            : 'Statut',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selectedStatus != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selectedStatus != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      avatar: selectedStatus != null
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      backgroundColor: selectedStatus != null
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasFilter)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Effacer'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
        ],
      ),
    );
  }
}
