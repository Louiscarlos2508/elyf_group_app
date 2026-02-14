import 'package:flutter/material.dart';
import '../../application/providers/filter_providers.dart';
import '../../domain/entities/maintenance_ticket.dart';

class MaintenanceFilters extends StatelessWidget {
  const MaintenanceFilters({
    super.key,
    required this.selectedStatus,
    required this.selectedArchiveFilter,
    required this.onStatusChanged,
    required this.onArchiveFilterChanged,
    required this.onClear,
  });

  final MaintenanceStatus? selectedStatus;
  final ArchiveFilter selectedArchiveFilter;
  final ValueChanged<MaintenanceStatus?> onStatusChanged;
  final ValueChanged<ArchiveFilter> onArchiveFilterChanged;
  final VoidCallback onClear;

  String _getStatusLabel(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.open:
        return 'Ouvert';
      case MaintenanceStatus.inProgress:
        return 'En cours';
      case MaintenanceStatus.resolved:
        return 'Résolu';
      case MaintenanceStatus.closed:
        return 'Fermé';
    }
  }

  String _getArchiveLabel(ArchiveFilter filter) {
    switch (filter) {
      case ArchiveFilter.active:
        return 'Actifs';
      case ArchiveFilter.archived:
        return 'Archivés';
      case ArchiveFilter.all:
        return 'Tous';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilter = selectedStatus != null || selectedArchiveFilter != ArchiveFilter.active;

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
                   _FilterChip<ArchiveFilter>(
                    label: 'Affichage',
                    value: selectedArchiveFilter,
                    options: ArchiveFilter.values,
                    getLabel: _getArchiveLabel,
                    onChanged: (v) => onArchiveFilterChanged(v ?? ArchiveFilter.active),
                    showCheckmark: false,
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<MaintenanceStatus?>(
                    initialValue: selectedStatus,
                    onSelected: onStatusChanged,
                    itemBuilder: (context) => [
                      const PopupMenuItem<MaintenanceStatus?>(
                        value: null,
                        child: Text('Tous les statuts'),
                      ),
                      ...MaintenanceStatus.values.map(
                        (status) => PopupMenuItem<MaintenanceStatus?>(
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

class _FilterChip<T> extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.getLabel,
    required this.onChanged,
    this.showCheckmark = true,
  });

  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) getLabel;
  final ValueChanged<T?>? onChanged;
  final bool showCheckmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value != null;

    return PopupMenuButton<T?>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        ...options.map(
          (option) =>
              PopupMenuItem<T?>(value: option, child: Text(getLabel(option))),
        ),
      ],
      child: Chip(
        label: Text(
          value != null ? getLabel(value as T) : label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        avatar: (isSelected && showCheckmark)
            ? Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
            : null,
        backgroundColor: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
