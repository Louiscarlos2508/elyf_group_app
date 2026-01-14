import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/utils/responsive_helper.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/enterprise.dart';

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
    final isMobile = ResponsiveHelper.isMobile(context);
    final horizontalPadding = ResponsiveHelper.adaptiveHorizontalPadding(
      context,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding.left,
        0,
        horizontalPadding.right,
        isMobile ? 8 : 12,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: isMobile
            ? _buildMobileLayout(context, theme, typeService)
            : _buildDesktopLayout(context, theme, typeService),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    dynamic typeService,
  ) {
    return InkWell(
      onTap: onNavigate,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    typeService.getTypeIcon(enterprise.type),
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enterprise.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Chip(
                            label: Text(
                              typeService.getTypeLabel(enterprise.type),
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          _StatusChip(isActive: enterprise.isActive),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'toggle':
                        onToggleStatus();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                      case 'navigate':
                        onNavigate();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'navigate',
                      child: Row(
                        children: [
                          Icon(
                            Icons.open_in_new,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text('Ouvrir'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            enterprise.isActive
                                ? Icons.block
                                : Icons.check_circle,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(enterprise.isActive ? 'Désactiver' : 'Activer'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Supprimer',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (enterprise.description != null &&
                enterprise.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                enterprise.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    dynamic typeService,
  ) {
    return ListTile(
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
