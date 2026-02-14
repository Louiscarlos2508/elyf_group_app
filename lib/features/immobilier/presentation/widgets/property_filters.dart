import 'package:flutter/material.dart';

import '../../domain/entities/property.dart';
import '../../application/providers/filter_providers.dart'; // Add import for ArchiveFilter

/// Widget pour filtrer les propriétés.
class PropertyFilters extends StatelessWidget {
  const PropertyFilters({
    super.key,
    this.selectedStatus,
    this.selectedType,
    required this.selectedArchiveFilter, // Make required
    this.onStatusChanged,
    this.onTypeChanged,
    this.onArchiveFilterChanged, // Add to constructor
    this.onClear,
  });

  final PropertyStatus? selectedStatus;
  final PropertyType? selectedType;
  final ArchiveFilter selectedArchiveFilter;
  final ValueChanged<PropertyStatus?>? onStatusChanged;
  final ValueChanged<PropertyType?>? onTypeChanged;
  final ValueChanged<ArchiveFilter>? onArchiveFilterChanged;
  final VoidCallback? onClear;

  String _getStatusLabel(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available:
        return 'Disponible';
      case PropertyStatus.rented:
        return 'Louée';
      case PropertyStatus.maintenance:
        return 'En maintenance';
      case PropertyStatus.sold:
        return 'Vendue';
    }
  }

  String _getTypeLabel(PropertyType type) {
    switch (type) {
      case PropertyType.house:
        return 'Maison';
      case PropertyType.apartment:
        return 'Appartement';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.commercial:
        return 'Commercial';
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
    final hasFilters = selectedStatus != null || selectedType != null || selectedArchiveFilter != ArchiveFilter.active;

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
                    onChanged: (v) => onArchiveFilterChanged?.call(v ?? ArchiveFilter.active),
                    showCheckmark: false,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip<PropertyStatus>(
                    label: 'Statut',
                    value: selectedStatus,
                    options: PropertyStatus.values,
                    getLabel: _getStatusLabel,
                    onChanged: onStatusChanged,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip<PropertyType>(
                    label: 'Type',
                    value: selectedType,
                    options: PropertyType.values,
                    getLabel: _getTypeLabel,
                    onChanged: onTypeChanged,
                  ),
                ],
              ),
            ),
          ),
          if (hasFilters)
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
        PopupMenuItem<T?>(value: null, child: Text('Tous les $label')),
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
