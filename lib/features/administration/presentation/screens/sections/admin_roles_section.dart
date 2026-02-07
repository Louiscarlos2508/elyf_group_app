import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/core.dart';
import 'dialogs/create_role_dialog.dart';
import 'dialogs/edit_role_dialog.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart'
    show currentUserIdProvider;
import '../../widgets/admin_shimmers.dart';

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
      NotificationService.showInfo(
        context,
        'Les rôles système ne peuvent pas être supprimés',
      );
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

        await ref
            .read(adminControllerProvider)
            .deleteRole(role.id, currentUserId: currentUserId, roleData: role);
        
        // Attendre un peu pour que la base de données soit à jour
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Invalider le provider pour forcer le rafraîchissement
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
    final enterpriseModuleUsersAsync = ref.watch(enterpriseModuleUsersProvider);

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
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Gestion des Rôles',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => _handleCreateRole(context, ref),
                              icon: const Icon(Icons.add_rounded),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              label: const Text('Nouveau Rôle'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configurez les accès par défaut ou créez vos propres modèles',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
                // Rôles Système (Prédéfinis)
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    'Rôles Système',
                    'Modèles officiels intégrés par défaut',
                    Icons.verified_user_outlined,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final systemRoles = roles.where((r) => r.isSystemRole).toList();
                    if (index >= systemRoles.length) return null;
                    final role = systemRoles[index];
                    return _buildRoleCard(context, ref, role, usersByRole[role.id] ?? 0);
                  }, childCount: roles.where((r) => r.isSystemRole).length),
                ),

                // Rôles Personnalisés
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    'Rôles Personnalisés',
                    'Modèles créés pour vos besoins spécifiques',
                    Icons.dashboard_customize_outlined,
                  ),
                ),
                if (roles.every((r) => r.isSystemRole))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Text(
                          'Aucun rôle personnalisé défini. Utilisez le bouton "Nouveau Rôle" pour en créer un.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final customRoles = roles.where((r) => !r.isSystemRole).toList();
                      if (index >= customRoles.length) return null;
                      final role = customRoles[index];
                      return _buildRoleCard(context, ref, role, usersByRole[role.id] ?? 0);
                    }, childCount: roles.where((r) => !r.isSystemRole).length),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
          loading: () => AdminShimmers.enterpriseListShimmer(context),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
        );
      },
      loading: () => AdminShimmers.enterpriseListShimmer(context),
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
              Text('Erreur de chargement', style: theme.textTheme.titleLarge),
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

  Widget _buildSectionHeader(
      BuildContext context, String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(
      BuildContext context, WidgetRef ref, UserRole role, int userCount) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: role.isSystemRole
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              role.isSystemRole ? Icons.verified_user : Icons.person_outline,
              color: role.isSystemRole
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            ),
          ),
          title: Text(
            role.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${role.permissions.length} permissions • $userCount utilisateur${userCount > 1 ? 's' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _handleEditRole(context, ref, role),
                tooltip: 'Modifier',
              ),
              if (!role.isSystemRole)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _handleDeleteRole(context, ref, role),
                  tooltip: 'Supprimer',
                ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Description',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Types d\'entreprise autorisés',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: role.allowedEnterpriseTypes.isEmpty
                        ? [
                            Chip(
                              label: const Text('Tous les types'),
                              backgroundColor: theme.colorScheme.surface,
                              side: BorderSide(
                                  color: theme.colorScheme.outlineVariant),
                              visualDensity: VisualDensity.compact,
                            )
                          ]
                        : role.allowedEnterpriseTypes.map((type) {
                            return Chip(
                              label: Text(type.name),
                              backgroundColor: theme.colorScheme.surface,
                              side: BorderSide(
                                  color: theme.colorScheme.outlineVariant),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
