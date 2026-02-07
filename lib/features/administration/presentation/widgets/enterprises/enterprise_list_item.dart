import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/utils/responsive_helper.dart';
import '../../../domain/entities/enterprise.dart';

/// Widget for displaying a single enterprise in the list.
class EnterpriseListItem extends ConsumerWidget {
  const EnterpriseListItem({
    super.key,
    required this.enterprise,
    this.isPointOfSale = false,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onViewDetails,
    required this.onManageAccess,
  });

  final Enterprise enterprise;
  final bool isPointOfSale;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;
  final VoidCallback onManageAccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final horizontalPadding = ResponsiveHelper.adaptiveHorizontalPadding(
      context,
    );

    return Container(
      margin: EdgeInsets.fromLTRB(
        horizontalPadding.left,
        0,
        horizontalPadding.right,
        isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: isMobile
            ? _buildMobileLayout(context, theme)
            : _buildDesktopLayout(context, theme),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: onViewDetails,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icône avec couleur du module
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: enterprise.type.module.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    enterprise.type.icon,
                    color: enterprise.type.module.color,
                    size: 24,
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
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            enterprise.type.icon,
                            size: 14,
                            color: enterprise.type.module.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            enterprise.type.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: enterprise.type.module.color,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menu d'actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'view': onViewDetails(); break;
                      case 'edit': onEdit(); break;
                      case 'access': onManageAccess(); break;
                      case 'toggle': onToggleStatus(); break;
                      case 'delete': onDelete(); break;
                    }
                  },
                  itemBuilder: (context) => [
                    buildPopupItem(
                      icon: Icons.visibility_outlined,
                      label: 'Voir Détails',
                      value: 'view',
                      color: theme.colorScheme.primary,
                    ),
                    buildPopupItem(
                      icon: Icons.edit_outlined,
                      label: 'Modifier',
                      value: 'edit',
                      color: theme.colorScheme.primary,
                    ),
                    buildPopupItem(
                      icon: Icons.people_outline,
                      label: 'Accès',
                      value: 'access',
                      color: theme.colorScheme.primary,
                    ),
                    const PopupMenuDivider(),
                    buildPopupItem(
                      icon: enterprise.isActive
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                      label: enterprise.isActive ? 'Désactiver' : 'Activer',
                      value: 'toggle',
                      color: enterprise.isActive ? Colors.orange : Colors.green,
                    ),
                    buildPopupItem(
                      icon: Icons.delete_outline,
                      label: 'Supprimer',
                      value: 'delete',
                      color: theme.colorScheme.error,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Badges
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (enterprise.type.isMain)
                  _Badge(
                    label: 'Société Principale',
                    color: enterprise.type.module.color,
                    icon: Icons.business,
                  ),
                if (isPointOfSale)
                  _Badge(
                    label: 'Point de vente',
                    color: Colors.blue,
                    icon: Icons.store,
                  ),
                _StatusBadge(isActive: enterprise.isActive),
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
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icône avec couleur du module
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: enterprise.type.module.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enterprise.type.module.color.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              enterprise.type.icon,
              color: enterprise.type.module.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        enterprise.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  enterprise.type.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: enterprise.type.module.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (enterprise.type.isMain)
                      _Badge(
                        label: 'Société Principale',
                        color: enterprise.type.module.color,
                        icon: Icons.business,
                      ),
                    if (isPointOfSale)
                      _Badge(
                        label: 'Point de vente',
                        color: Colors.blue,
                        icon: Icons.store,
                      ),
                    _StatusBadge(isActive: enterprise.isActive),
                  ],
                ),
                if (enterprise.description != null &&
                    enterprise.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
          const SizedBox(width: 16),
          // Actions
          _ActionButtons(
            isActive: enterprise.isActive,
            onEdit: onEdit,
            onToggleStatus: onToggleStatus,
            onDelete: onDelete,
            onViewDetails: onViewDetails,
            onManageAccess: onManageAccess,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isActive,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onViewDetails,
    required this.onManageAccess,
  });

  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;
  final VoidCallback onManageAccess;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Actions sûres - toujours visibles
        IconButton.outlined(
          icon: const Icon(Icons.visibility_outlined, size: 20),
          onPressed: onViewDetails,
          tooltip: 'Voir Détails',
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: onEdit,
          tooltip: 'Modifier',
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          icon: const Icon(Icons.people_outline, size: 20),
          onPressed: onManageAccess,
          tooltip: 'Accès',
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        // Menu pour actions dangereuses
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          tooltip: 'Plus d\'actions',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onSelected: (value) {
            switch (value) {
              case 'toggle': onToggleStatus(); break;
              case 'delete': onDelete(); break;
            }
          },
          itemBuilder: (context) => [
            buildPopupItem(
              icon: isActive
                  ? Icons.block_outlined
                  : Icons.check_circle_outline,
              label: isActive ? 'Désactiver' : 'Activer',
              value: 'toggle',
              color: isActive ? Colors.orange : Colors.green,
            ),
            buildPopupItem(
              icon: Icons.delete_outline,
              label: 'Supprimer',
              value: 'delete',
              color: theme.colorScheme.error,
              isDestructive: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// Helper function to build consistent popup menu items
PopupMenuItem<String> buildPopupItem({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
  bool isDestructive = false,
}) {
  return PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: isDestructive
              ? TextStyle(color: color, fontWeight: FontWeight.bold)
              : null,
        ),
      ],
    ),
  );
}
