import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/administration/domain/entities/enterprise.dart';
import '../../../core/tenant/tenant_provider.dart';

/// Widget pour sélectionner l'entreprise active
///
/// Affiche un dialogue permettant à l'utilisateur de choisir parmi
/// les entreprises auxquelles il a accès.
class EnterpriseSelectorWidget extends ConsumerWidget {
  const EnterpriseSelectorWidget({
    super.key,
    this.showLabel = true,
    this.compact = false,
  });

  /// Afficher le label "Entreprise"
  final bool showLabel;

  /// Mode compact (icône seulement)
  final bool compact;

  /// Affiche le sélecteur d'entreprise depuis n'importe quel contexte
  static Future<void> showSelector(BuildContext context, WidgetRef ref) async {
    final accessibleEnterprisesAsync = ref.read(
      userAccessibleEnterprisesProvider,
    );

    final accessibleEnterprises = accessibleEnterprisesAsync.when(
      data: (enterprises) => enterprises,
      loading: () => <Enterprise>[],
      error: (_, __) => <Enterprise>[],
    );

    if (accessibleEnterprises.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune entreprise accessible')),
        );
      }
      return;
    }

    // Récupérer l'entreprise active
    final activeEnterpriseAsync = ref.read(activeEnterpriseProvider);
    final activeEnterprise = activeEnterpriseAsync.when(
      data: (enterprise) => enterprise,
      loading: () => null,
      error: (_, __) => null,
    );
    final activeEnterpriseId = activeEnterprise?.id;

    if (!context.mounted) return;

    final selected = await showDialog<Enterprise>(
      context: context,
      builder: (context) => _EnterpriseSelectorDialog(
        enterprises: accessibleEnterprises,
        selectedEnterpriseId: activeEnterpriseId,
      ),
    );

    if (selected != null && context.mounted) {
      final tenantNotifier = ref.read(activeEnterpriseIdProvider.notifier);
      await tenantNotifier.setActiveEnterpriseId(selected.id);

      // Rafraîchir les providers qui dépendent de l'entreprise active
      ref.invalidate(activeEnterpriseProvider);

      // Attendre que le provider soit rechargé avant de naviguer
      try {
        await ref.read(activeEnterpriseProvider.future);
      } catch (e) {
        // Ignorer les erreurs, on naviguera quand même
      }

      // Rediriger vers le menu des modules pour recharger avec la nouvelle entreprise
      if (context.mounted) {
        context.go('/modules');
        
        // Afficher le message de confirmation après la navigation
        // Utiliser un délai pour s'assurer que le nouvel écran est monté
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Entreprise sélectionnée : ${selected.name}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _showEnterpriseSelector(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Récupérer les entreprises accessibles
    final accessibleEnterprisesAsync = ref.read(
      userAccessibleEnterprisesProvider,
    );

    final accessibleEnterprises = accessibleEnterprisesAsync.when(
      data: (enterprises) => enterprises,
      loading: () => <Enterprise>[],
      error: (_, __) => <Enterprise>[],
    );

    if (accessibleEnterprises.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune entreprise accessible')),
        );
      }
      return;
    }

    // Récupérer l'entreprise active
    final activeEnterpriseAsync = ref.read(activeEnterpriseProvider);
    final activeEnterprise = activeEnterpriseAsync.when(
      data: (enterprise) => enterprise,
      loading: () => null,
      error: (_, __) => null,
    );
    final activeEnterpriseId = activeEnterprise?.id;

    if (!context.mounted) return;

    final selected = await showDialog<Enterprise>(
      context: context,
      builder: (context) => _EnterpriseSelectorDialog(
        enterprises: accessibleEnterprises,
        selectedEnterpriseId: activeEnterpriseId,
      ),
    );

    if (selected != null && context.mounted) {
      final tenantNotifier = ref.read(activeEnterpriseIdProvider.notifier);
      await tenantNotifier.setActiveEnterpriseId(selected.id);

      // Rafraîchir les providers qui dépendent de l'entreprise active
      ref.invalidate(activeEnterpriseProvider);

      // Attendre que le provider soit rechargé avant de naviguer
      try {
        await ref.read(activeEnterpriseProvider.future);
      } catch (e) {
        // Ignorer les erreurs, on naviguera quand même
      }

      // Rediriger vers le menu des modules pour recharger avec la nouvelle entreprise
      if (context.mounted) {
        context.go('/modules');
        
        // Afficher le message de confirmation après la navigation
        // Utiliser un délai pour s'assurer que le nouvel écran est monté
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Entreprise sélectionnée : ${selected.name}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);

    if (compact) {
      return IconButton(
        icon: const Icon(Icons.business_outlined),
        tooltip: 'Changer d\'entreprise',
        onPressed: () => _showEnterpriseSelector(context, ref),
      );
    }

    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null) {
          return _buildSelectorButton(
            context,
            ref,
            theme,
            label: 'Sélectionner une entreprise',
            icon: Icons.business_outlined,
          );
        }

        return _buildSelectorButton(
          context,
          ref,
          theme,
          label: showLabel ? 'Entreprise' : null,
          enterpriseName: enterprise.name,
          icon: Icons.business,
        );
      },
      loading: () => _buildSelectorButton(
        context,
        ref,
        theme,
        label: showLabel ? 'Entreprise' : null,
        enterpriseName: 'Chargement...',
        icon: Icons.business_outlined,
        enabled: false,
      ),
      error: (error, stack) => _buildSelectorButton(
        context,
        ref,
        theme,
        label: showLabel ? 'Entreprise' : null,
        enterpriseName: 'Erreur',
        icon: Icons.error_outline,
      ),
    );
  }

  Widget _buildSelectorButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme, {
    String? label,
    String? enterpriseName,
    required IconData icon,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? () => _showEnterpriseSelector(context, ref) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceContainerLow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            if (label != null || enterpriseName != null) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null)
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (enterpriseName != null)
                    Text(
                      enterpriseName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            ],
            if (enabled) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.unfold_more,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialogue de sélection d'entreprise
class _EnterpriseSelectorDialog extends StatelessWidget {
  const _EnterpriseSelectorDialog({
    required this.enterprises,
    this.selectedEnterpriseId,
  });

  final List<Enterprise> enterprises;
  final String? selectedEnterpriseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Use standardized header pattern
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.business_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entreprise',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Sélectionner l\'entreprise active',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(),
              ),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  shrinkWrap: true,
                  itemCount: enterprises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final enterprise = enterprises[index];
                    final isSelected = enterprise.id == selectedEnterpriseId;
                    
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(enterprise),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                                : theme.colorScheme.outline.withValues(alpha: 0.1),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.business,
                                size: 20,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    enterprise.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected 
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (enterprise.description != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      enterprise.description!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
