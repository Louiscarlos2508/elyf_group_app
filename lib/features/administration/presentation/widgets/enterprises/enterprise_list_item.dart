import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/enterprise.dart';
import '../../../domain/services/enterprise_type_service.dart';

/// Widget for displaying a single enterprise in the list.
class EnterpriseListItem extends ConsumerWidget {
  const EnterpriseListItem({
    super.key,
    required this.enterprise,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onNavigate,
  });

  final Enterprise enterprise;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final typeService = ref.read(enterpriseTypeServiceProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              typeService.getTypeIcon(enterprise.type),
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            enterprise.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(enterprise.description ?? ''),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(typeService.getTypeLabel(enterprise.type)),
                    visualDensity: VisualDensity.compact,
                  ),
                  _StatusChip(isActive: enterprise.isActive),
                ],
              ),
            ],
          ),
          trailing: _ActionButtons(
            isActive: enterprise.isActive,
            onEdit: onEdit,
            onToggleStatus: onToggleStatus,
            onDelete: onDelete,
            onNavigate: onNavigate,
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isActive) {
      return Chip(
        label: const Text('Active'),
        visualDensity: VisualDensity.compact,
        backgroundColor: theme.colorScheme.primaryContainer,
      );
    }

    return const Chip(
      label: Text('Inactive'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isActive,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onNavigate,
  });

  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
          tooltip: 'Modifier',
        ),
        IconButton(
          icon: Icon(isActive ? Icons.block : Icons.check_circle),
          onPressed: onToggleStatus,
          tooltip: isActive ? 'Désactiver' : 'Activer',
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
          tooltip: 'Supprimer',
        ),
        IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: onNavigate,
          tooltip: 'Ouvrir l\'entreprise',
        ),
      ],
    );
  }
}
