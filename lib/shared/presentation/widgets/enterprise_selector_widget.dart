import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/administration/domain/entities/enterprise.dart';
import '../../../core/tenant/tenant_provider.dart';

/// Styles de présentation pour le sélecteur d'entreprise
enum EnterpriseSelectorStyle {
  /// Style standard avec label et bordure (pour les formulaires/écrans de paramétrage)
  standard,

  /// Style compact (icône uniquement)
  compact,

  /// Style AppBar (chip premium avec nom de l'entreprise)
  appBar,
}

/// Widget pour sélectionner l'entreprise active
///
/// Affiche un dialogue permettant à l'utilisateur de choisir parmi
/// les entreprises auxquelles il a accès.
class EnterpriseSelectorWidget extends ConsumerWidget {
  const EnterpriseSelectorWidget({
    super.key,
    this.showLabel = true,
    this.style = EnterpriseSelectorStyle.standard,
  });

  /// Afficher le label "Entreprise" (uniquement style standard)
  final bool showLabel;

  /// Style de présentation
  final EnterpriseSelectorStyle style;

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
    final accessibleEnterprisesAsync = ref.watch(userAccessibleEnterprisesProvider);

    // Ne rien afficher si l'utilisateur n'a qu'une seule entreprise
    final canShow = accessibleEnterprisesAsync.when(
      data: (enterprises) => enterprises.length > 1,
      loading: () => false,
      error: (_, __) => false,
    );

    if (!canShow) {
      return const SizedBox.shrink();
    }

    if (style == EnterpriseSelectorStyle.compact) {
      return IconButton(
        icon: const Icon(Icons.business_outlined),
        tooltip: 'Changer d\'entreprise',
        onPressed: () => _showEnterpriseSelector(context, ref),
      );
    }

    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null) {
          if (style == EnterpriseSelectorStyle.appBar) {
            return _buildAppBarSelector(context, ref, theme, null);
          }
          return _buildSelectorButton(
            context,
            ref,
            theme,
            label: 'Sélectionner une entreprise',
            icon: Icons.business_outlined,
          );
        }

        if (style == EnterpriseSelectorStyle.appBar) {
          return _buildAppBarSelector(context, ref, theme, enterprise);
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
      loading: () => style == EnterpriseSelectorStyle.appBar
          ? _buildAppBarSelector(context, ref, theme, null, isLoading: true)
          : _buildSelectorButton(
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

  Widget _buildAppBarSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Enterprise? enterprise, {
    bool isLoading = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => _showEnterpriseSelector(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  enterprise?.type.icon ?? Icons.business_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isLoading ? '...' : (enterprise?.name ?? 'Sélect.'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
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

/// Dialogue de sélection d'entreprise premium
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
    final isDark = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          decoration: BoxDecoration(
            color: (isDark ? Colors.grey[900] : Colors.white)!.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.business_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Changer d\'espace',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Entreprises, dépôts et points de vente',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                        ),
                    ),
                  ],
                ),
              ),
              
              // List
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  shrinkWrap: true,
                  itemCount: enterprises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final enterprise = enterprises[index];
                    final isSelected = enterprise.id == selectedEnterpriseId;
                    
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(enterprise),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                                : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(alpha: 0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  enterprise.type.icon,
                                  size: 24,
                                  color: isSelected
                                      ? theme.colorScheme.primary
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
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (enterprise.description != null) ...[
                                      const SizedBox(height: 4),
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
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: theme.colorScheme.onPrimary,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

