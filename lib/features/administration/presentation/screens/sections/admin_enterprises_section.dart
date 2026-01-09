import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import '../../../domain/entities/enterprise.dart';
import '../../../domain/services/enterprise_type_service.dart';
import 'dialogs/create_enterprise_dialog.dart';
import 'dialogs/edit_enterprise_dialog.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';

/// Section pour gérer les entreprises
class AdminEnterprisesSection extends ConsumerWidget {
  const AdminEnterprisesSection({super.key});

  Future<void> _handleCreateEnterprise(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<Enterprise>(
      context: context,
      builder: (context) => const CreateEnterpriseDialog(),
    );

    if (result != null) {
      try {
        await ref
            .read(enterpriseControllerProvider)
            .createEnterprise(result);
        ref.invalidate(enterprisesProvider);
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Entreprise créée avec succès');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> _handleEditEnterprise(
    BuildContext context,
    WidgetRef ref,
    Enterprise enterprise,
  ) async {
    final result = await showDialog<Enterprise>(
      context: context,
      builder: (context) => EditEnterpriseDialog(enterprise: enterprise),
    );

    if (result != null) {
      try {
        await ref
            .read(enterpriseControllerProvider)
            .updateEnterprise(result);
        ref.invalidate(enterprisesProvider);
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Entreprise modifiée avec succès');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> _handleToggleStatus(
    BuildContext context,
    WidgetRef ref,
    Enterprise enterprise,
  ) async {
    try {
      await ref
          .read(enterpriseControllerProvider)
          .toggleEnterpriseStatus(enterprise.id, !enterprise.isActive);
      ref.invalidate(enterprisesProvider);
      if (context.mounted) {
        NotificationService.showInfo(context, 
              enterprise.isActive
                  ? 'Entreprise désactivée'
                  : 'Entreprise activée',
            );
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, e.toString());
      }
    }
  }

  Future<void> _handleDeleteEnterprise(
    BuildContext context,
    WidgetRef ref,
    Enterprise enterprise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'entreprise'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${enterprise.name}" ?',
        ),
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
        await ref
            .read(enterpriseControllerProvider)
            .deleteEnterprise(enterprise.id);
        ref.invalidate(enterprisesProvider);
        if (context.mounted) {
          NotificationService.showSuccess(context, 'Entreprise supprimée');
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(context, e.toString());
        }
      }
    }
  }

  void _navigateToEnterprise(
    BuildContext context,
    Enterprise enterprise,
  ) {
    final moduleRoute = '/modules/${enterprise.type}/${enterprise.id}';
    context.go(moduleRoute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enterprisesAsync = ref.watch(enterprisesProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Entreprises',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez les entreprises du groupe ELYF',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton.icon(
              onPressed: () => _handleCreateEnterprise(context, ref),
              icon: const Icon(Icons.add_business),
              label: const Text('Nouvelle Entreprise'),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        enterprisesAsync.when(
          data: (enterprises) {
            if (enterprises.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune entreprise',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Créez votre première entreprise',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final enterprise = enterprises[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            ref.read(enterpriseTypeServiceProvider).getTypeIcon(enterprise.type),
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
                                  label: Text(ref.read(enterpriseTypeServiceProvider).getTypeLabel(enterprise.type)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (enterprise.isActive)
                                  Chip(
                                    label: const Text('Active'),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                  )
                                else
                                  Chip(
                                    label: const Text('Inactive'),
                                    visualDensity: VisualDensity.compact,
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
                              onPressed: () => _handleEditEnterprise(
                                context,
                                ref,
                                enterprise,
                              ),
                              tooltip: 'Modifier',
                            ),
                            IconButton(
                              icon: Icon(
                                enterprise.isActive
                                    ? Icons.block
                                    : Icons.check_circle,
                              ),
                              onPressed: () => _handleToggleStatus(
                                context,
                                ref,
                                enterprise,
                              ),
                              tooltip: enterprise.isActive
                                  ? 'Désactiver'
                                  : 'Activer',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _handleDeleteEnterprise(
                                context,
                                ref,
                                enterprise,
                              ),
                              tooltip: 'Supprimer',
                            ),
                            IconButton(
                              icon: const Icon(Icons.open_in_new),
                              onPressed: () => _navigateToEnterprise(
                                context,
                                enterprise,
                              ),
                              tooltip: 'Ouvrir l\'entreprise',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  );
                },
                childCount: enterprises.length,
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverToBoxAdapter(
            child: Center(
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
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

