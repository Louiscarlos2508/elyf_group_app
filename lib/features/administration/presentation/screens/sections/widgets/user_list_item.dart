import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/domain/entities/user.dart';
import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import '../../../../application/providers.dart';
import '../../../../../../shared/utils/notification_service.dart';

/// User list item widget extracted for better code organization.
///
/// Displays a single user with their assignments in an ExpansionTile.
class UserListItem extends ConsumerWidget {
  const UserListItem({
    super.key,
    required this.user,
    required this.userAssignments,
    required this.onEdit,
    required this.onAssign,
    required this.onToggle,
    required this.onDelete,
  });

  final User user;
  final List<EnterpriseModuleUser> userAssignments;
  final VoidCallback onEdit;
  final VoidCallback onAssign;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enterprisesAsync = ref.watch(enterprisesProvider);

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
          leading: _buildUserAvatar(theme),
          title: Text(
            user.fullName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: _UserListItemSubtitle(
            user: user,
            assignments: userAssignments,
          ),
          trailing: _UserListItemActions(
            user: user,
            onEdit: onEdit,
            onAssign: onAssign,
            onToggle: onToggle,
            onDelete: onDelete,
          ),
          childrenPadding: EdgeInsets.zero,
          expandedAlignment: Alignment.topLeft,
          children: [
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            ...userAssignments.map((assignment) => _buildAssignmentItem(
              context, 
              ref, 
              theme, 
              assignment,
              enterprisesAsync.value ?? [],
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(ThemeData theme) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            user.firstName[0].toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: user.isActive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentItem(
    BuildContext context, 
    WidgetRef ref, 
    ThemeData theme, 
    EnterpriseModuleUser assignment,
    List<Enterprise> enterprises,
  ) {
    // Trouver le nom de l'entreprise
    final enterprise = enterprises.where(
      (e) => e.id == assignment.enterpriseId,
    ).firstOrNull;
    final enterpriseName = enterprise?.name ?? assignment.enterpriseId;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getModuleIcon(assignment.moduleId),
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        enterpriseName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Module: ${assignment.moduleId.toUpperCase()} • Rôles: ${assignment.roleIds.join(", ")}',
        style: theme.textTheme.labelSmall,
      ),
      trailing: IconButton(
        icon: Icon(Icons.remove_circle_outline, 
          size: 18, 
          color: theme.colorScheme.error.withValues(alpha: 0.7)
        ),
        onPressed: () => _handleRemove(context, ref, assignment),
      ),
    );
  }

  IconData _getModuleIcon(String moduleId) {
    switch (moduleId) {
      case 'gaz': return Icons.local_gas_station_outlined;
      case 'eau_minerale': return Icons.water_drop_outlined;
      case 'boutique': return Icons.shopping_bag_outlined;
      case 'orange_money': return Icons.account_balance_wallet_outlined;
      case 'administration': return Icons.admin_panel_settings_outlined;
      default: return Icons.apps;
    }
  }

  Future<void> _handleRemove(
    BuildContext context, 
    WidgetRef ref, 
    EnterpriseModuleUser assignment
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer l\'assignation'),
        content: Text(
          'Voulez-vous vraiment retirer l\'accès à :\n'
          '${assignment.enterpriseId} (${assignment.moduleId}) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(adminControllerProvider)
            .removeUserFromEnterprise(
              assignment.userId,
              assignment.enterpriseId,
              assignment.moduleId,
            );
        await Future.delayed(const Duration(milliseconds: 100));
        ref.invalidate(enterpriseModuleUsersProvider);
        ref.invalidate(userEnterpriseModuleUsersProvider(assignment.userId));
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Accès retiré');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }
}

/// Subtitle widget for user list item.
class _UserListItemSubtitle extends StatelessWidget {
  const _UserListItemSubtitle({required this.user, required this.assignments});

  final User user;
  final List<EnterpriseModuleUser> assignments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '@${user.username}${user.email != null ? " • ${user.email}" : ""}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (assignments.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ...assignments.take(2).map((a) => _buildMiniBadge(theme, a)),
              if (assignments.length > 2)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${assignments.length - 2}',
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMiniBadge(ThemeData theme, EnterpriseModuleUser a) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${a.moduleId.toUpperCase()} : ${a.roleIds.join(", ")}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Actions widget for user list item.
class _UserListItemActions extends StatelessWidget {
  const _UserListItemActions({
    required this.user,
    required this.onEdit,
    required this.onAssign,
    required this.onToggle,
    required this.onDelete,
  });

  final User user;
  final VoidCallback onEdit;
  final VoidCallback onAssign;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!user.isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Inactif',
              style: theme.textTheme.labelSmall,
            ),
          ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'assign':
                onAssign();
                break;
              case 'toggle':
                onToggle();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'assign',
              child: Row(
                children: [
                  Icon(Icons.business, size: 20),
                  SizedBox(width: 8),
                  Text('Attribuer entreprise'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    user.isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'Désactiver' : 'Activer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
