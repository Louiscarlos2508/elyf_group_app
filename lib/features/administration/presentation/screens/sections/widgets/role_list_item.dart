import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core.dart' show UserRole;
import '../../../../../../core/permissions/services/permission_registry.dart';

/// Specialized widget for displaying a role in a premium card style.
/// 
/// Matches the visual language established in UserListItem.
class RoleListItem extends ConsumerWidget {
  const RoleListItem({
    super.key,
    required this.role,
    required this.userCount,
    required this.onEdit,
    required this.onDelete,
  });

  final UserRole role;
  final int userCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          leading: _buildRoleIcon(theme),
          title: Text(
            role.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: _RoleListItemSubtitle(
            role: role,
            userCount: userCount,
          ),
          trailing: _RoleListItemActions(
            role: role,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
          childrenPadding: EdgeInsets.zero,
          expandedAlignment: Alignment.topLeft,
          children: [
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            _buildPermissionsSummary(theme),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleIcon(ThemeData theme) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: (role.isSystemRole 
          ? theme.colorScheme.secondary 
          : theme.colorScheme.primary).withValues(alpha: 0.1),
      child: Icon(
        role.isSystemRole ? Icons.admin_panel_settings_rounded : Icons.shield_rounded,
        color: role.isSystemRole ? theme.colorScheme.secondary : theme.colorScheme.primary,
        size: 20,
      ),
    );
  }

  Widget _buildPermissionsSummary(ThemeData theme) {
    // Group permissions by module for display
    final registry = PermissionRegistry.instance;
    final moduleGroups = <String, List<String>>{};
    
    for (final permId in role.permissions) {
      final moduleId = registry.getModuleForPermission(permId) ?? 'Général';
      moduleGroups.putIfAbsent(moduleId, () => []).add(permId);
    }

    if (moduleGroups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Aucune permission assignée',
          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'PERMISSIONS PAR MODULE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...moduleGroups.entries.map((entry) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: entry.value.map((id) {
                    final permName = registry.getPermissionName(id) ?? id;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        permName,
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        )),
      ],
    );
  }
}

class _RoleListItemSubtitle extends StatelessWidget {
  const _RoleListItemSubtitle({required this.role, required this.userCount});

  final UserRole role;
  final int userCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildBadge(
              theme, 
              '${role.permissions.length} PERM.', 
              theme.colorScheme.primaryContainer,
              theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 6),
            if (userCount > 0)
              _buildBadge(
                theme, 
                '$userCount USERS', 
                theme.colorScheme.secondaryContainer,
                theme.colorScheme.onSecondaryContainer,
              ),
            if (role.isSystemRole) ...[
              const SizedBox(width: 6),
              _buildBadge(
                theme, 
                'SYSTÈME', 
                theme.colorScheme.tertiaryContainer,
                theme.colorScheme.onTertiaryContainer,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(ThemeData theme, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RoleListItemActions extends StatelessWidget {
  const _RoleListItemActions({
    required this.role,
    required this.onEdit,
    required this.onDelete,
  });

  final UserRole role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: onEdit,
          tooltip: 'Modifier',
        ),
        if (!role.isSystemRole)
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, 
              size: 20, 
              color: theme.colorScheme.error
            ),
            onPressed: onDelete,
            tooltip: 'Supprimer',
          ),
      ],
    );
  }
}
