import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/core.dart';
import 'dialogs/create_role_dialog.dart';
import 'dialogs/edit_role_dialog.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart' show currentUserIdProvider;

/// Section pour gérer les rôles.
class AdminRolesSection extends ConsumerWidget {
  const AdminRolesSection({super.key});

  Future<void> _handleCreateRole(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<UserRole>(
      context: context,
      builder: (context) => const CreateRoleDialog(),
    );

    if (result != null) {
      ref.invalidate(rolesProvider);
      if (context.mounted) {
        NotificationService.showSuccess(context, 'Rôle créé avec succès');
      }
    }
  }

  Future<void> _handleEditRole(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    final result = await showDialog<UserRole>(
      context: context,
      builder: (context) => EditRoleDialog(role: role),
    );

    if (result != null) {
      ref.invalidate(rolesProvider);
      if (context.mounted) {
        NotificationService.showSuccess(context, 'Rôle modifié avec succès');
      }
    }
  }

  Future<void> _handleDeleteRole(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    if (role.isSystemRole) {
      NotificationService.showInfo(context, 'Les rôles système ne peuvent pas être supprimés');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rôle'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${role.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Récupérer l'ID de l'utilisateur actuel pour l'audit trail
        final currentUserId = ref.read(currentUserIdProvider);

        await ref.read(adminControllerProvider).deleteRole(
          role.id,
          currentUserId: currentUserId,
          roleData: role,
        );
        ref.invalidate(rolesProvider);
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Rôle supprimé');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rolesAsync = ref.watch(rolesProvider);
    final enterpriseModuleUsersAsync =
        ref.watch(enterpriseModuleUsersProvider);
    
    return rolesAsync.when(
      data: (roles) {
        return enterpriseModuleUsersAsync.when(
          data: (assignments) {
            // Use statistics service to extract business logic from UI
            final statsService = ref.read(roleStatisticsServiceProvider);
            final usersByRole = statsService.countUsersByRole(
              roles: roles,
              assignments: assignments,
            );

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestion des Rôles',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Créez et gérez les rôles avec leurs permissions',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _handleCreateRole(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Nouveau Rôle'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (roles.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun rôle',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Créez votre premier rôle',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                  ],
                ),
              ),
            ),
                  )
                else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final role = roles[index];
                        final userCount = usersByRole[role.id] ?? 0;

                  return Card(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                        role.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                                  ),
                                ),
                                if (role.isSystemRole)
                                  Chip(
                                    label: const Text('Système'),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                  ),
                              ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(role.description),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Chip(
                                label: Text(
                                  '${role.permissions.length} permission${role.permissions.length > 1 ? 's' : ''}',
                                  style: theme.textTheme.labelSmall,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                                    if (userCount > 0)
                                Chip(
                                        label: Text(
                                          '$userCount utilisateur${userCount > 1 ? 's' : ''}',
                                          style: theme.textTheme.labelSmall,
                                        ),
                                  visualDensity: VisualDensity.compact,
                                        backgroundColor:
                                            theme.colorScheme.secondaryContainer,
                                ),
                            ],
                          ),
                        ],
                      ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                        icon: const Icon(Icons.edit),
                                  onPressed: () => _handleEditRole(context, ref, role),
                                  tooltip: 'Modifier',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: role.isSystemRole
                                      ? null
                                      : () => _handleDeleteRole(context, ref, role),
                                  tooltip: 'Supprimer',
                                ),
                              ],
                      ),
                            isThreeLine: true,
                    ),
                  );
                },
                childCount: roles.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
    );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
}
}
