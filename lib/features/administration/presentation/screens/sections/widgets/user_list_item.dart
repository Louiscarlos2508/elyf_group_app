import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/domain/entities/user.dart';
import 'package:elyf_groupe_app/core/auth/entities/enterprise_module_user.dart';
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Card(
        child: ExpansionTile(
          leading: CircleAvatar(child: Text(user.firstName[0].toUpperCase())),
          title: Text(
            user.fullName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
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
          children: userAssignments.map((assignment) {
            return ListTile(
              title: Text(
                '${assignment.enterpriseId} - ${assignment.moduleId}',
              ),
              subtitle: Text('Rôle: ${assignment.roleId}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Retirer l\'assignation',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Retirer l\'assignation'),
                      content: Text(
                        'Êtes-vous sûr de vouloir retirer cette assignation?\n\n'
                        'Entreprise: ${assignment.enterpriseId}\n'
                        'Module: ${assignment.moduleId}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Annuler'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
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
                      // Attendre un peu pour que la base de données soit à jour
                      await Future.delayed(const Duration(milliseconds: 100));
                      ref.invalidate(enterpriseModuleUsersProvider);
                      ref.invalidate(
                        userEnterpriseModuleUsersProvider(assignment.userId),
                      );
                      if (context.mounted) {
                        NotificationService.showSuccess(
                          context,
                          'Assignation retirée avec succès',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        NotificationService.showError(context, e.toString());
                      }
                    }
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
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
        Text('@${user.username}'),
        if (user.email != null) Text(user.email!),
        if (assignments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: assignments
                .take(3)
                .map(
                  (a) => Chip(
                    label: Text(
                      '${a.enterpriseId} - ${a.moduleId}',
                      style: theme.textTheme.labelSmall,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
          if (assignments.length > 3)
            Text(
              '+${assignments.length - 3} autres',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!user.isActive)
          const Chip(
            label: Text('Inactif'),
            visualDensity: VisualDensity.compact,
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
