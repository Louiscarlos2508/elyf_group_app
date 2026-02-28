import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers.dart';
import '../../../../../shared/utils/responsive_helper.dart';
import '../../../../../shared/widgets/actionable_empty_state.dart';
import '../../../domain/entities/enterprise.dart';
import '../../widgets/enterprises/enterprise_actions.dart';
import '../../widgets/enterprises/enterprise_list_item.dart';
import '../../widgets/enterprises/enterprise_tree_view.dart';
import '../../widgets/admin_shimmers.dart';

enum _ViewMode { list, tree }

/// Notifier for view mode
class _ViewModeNotifier extends Notifier<_ViewMode> {
  @override
  _ViewMode build() => _ViewMode.list;

  void setMode(_ViewMode mode) => state = mode;
}

/// View mode provider for enterprises section
final _enterprisesViewModeProvider = NotifierProvider<_ViewModeNotifier, _ViewMode>(_ViewModeNotifier.new);

/// Section pour gérer les entreprises
class AdminEnterprisesSection extends ConsumerWidget {
  const AdminEnterprisesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final combinedAsync = ref.watch(enterprisesWithSubTenantsProvider);
    
    // Log pour déboguer
    combinedAsync.whenData((combined) {
      final subCount = combined.where((item) => item.isSubTenant).length;
      developer.log(
        '🔵 AdminEnterprisesSection: ${combined.length} éléments au total ($subCount sous-tenants)',
        name: 'AdminEnterprisesSection',
      );
    });

    return CustomScrollView(
      slivers: [
        _buildHeader(context, theme),
        _buildViewToggle(context, ref),
        _buildCreateButton(context, ref),
        SliverToBoxAdapter(
          child: SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 24),
        ),
        combinedAsync.when(
          data: (combined) {
            final subCount = combined.where((item) => item.isSubTenant).length;
            developer.log(
              '🔵 AdminEnterprisesSection: Affichage de ${combined.length} éléments ($subCount sous-tenants)',
              name: 'AdminEnterprisesSection',
            );
            final viewMode = ref.watch(_enterprisesViewModeProvider);
            return viewMode == _ViewMode.tree
                ? _buildEnterprisesTree(context, ref, combined)
                : _buildEnterprisesList(context, ref, combined);
          },
          loading: () {
            final viewMode = ref.watch(_enterprisesViewModeProvider);
            return SliverToBoxAdapter(
              child: viewMode == _ViewMode.tree
                  ? AdminShimmers.enterpriseTreeShimmer(context, itemCount: 8)
                  : AdminShimmers.enterpriseListShimmer(context, itemCount: 5),
            );
          },
          error: (error, stack) {
            developer.log(
              '❌ AdminEnterprisesSection: Erreur: $error',
              name: 'AdminEnterprisesSection',
              error: error,
              stackTrace: stack,
            );
            return _buildErrorState(context, theme, error);
          },
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 24),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: ResponsiveHelper.adaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion des Entreprises',
              style: ResponsiveHelper.isMobile(context)
                  ? theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  : theme.textTheme.headlineMedium?.copyWith(
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
    );
  }

  Widget _buildCreateButton(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: ResponsiveHelper.adaptiveHorizontalPadding(context),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => EnterpriseActions.create(context, ref),
            icon: const Icon(Icons.add_business),
            label: Text(
              isMobile ? 'Nouvelle Entreprise' : 'Nouvelle Entreprise',
            ),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 12 : 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnterprisesList(
    BuildContext context,
    WidgetRef ref,
    List<({Enterprise enterprise, bool isSubTenant})> combined,
  ) {
    if (combined.isEmpty) {
      return SliverToBoxAdapter(
        child: ActionableEmptyState(
          icon: Icons.business,
          title: 'Aucune entreprise',
          subtitle: 'Commencez par créer votre première entreprise',
          actionLabel: 'Créer une entreprise',
          onAction: () => EnterpriseActions.create(context, ref),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = combined[index];
        return EnterpriseListItem(
          enterprise: item.enterprise,
          isPointOfSale: item.isSubTenant,
          onEdit: () => EnterpriseActions.edit(context, ref, item.enterprise),
          onToggleStatus: () =>
              EnterpriseActions.toggleStatus(context, ref, item.enterprise),
          onDelete: () => EnterpriseActions.delete(context, ref, item.enterprise),
          onViewDetails: () {
            // Afficher les détails de l'entreprise dans un dialog
            EnterpriseActions.viewDetails(context, ref, item.enterprise);
          },
          onManageAccess: () {
            // Naviguer vers la gestion des accès utilisateurs pour cette entreprise
            context.go('/admin/enterprises/${item.enterprise.id}/access');
          },
        );
      }, childCount: combined.length),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, Object error) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: ResponsiveHelper.adaptivePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: ResponsiveHelper.isMobile(context) ? 48 : 64,
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

  Widget _buildViewToggle(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(_enterprisesViewModeProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: ResponsiveHelper.adaptiveHorizontalPadding(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SegmentedButton<_ViewMode>(
              segments: const [
                ButtonSegment(
                  value: _ViewMode.list,
                  icon: Icon(Icons.list, size: 18),
                  label: Text('Liste'),
                ),
                ButtonSegment(
                  value: _ViewMode.tree,
                  icon: Icon(Icons.account_tree, size: 18),
                  label: Text('Arbre'),
                ),
              ],
              selected: {viewMode},
              onSelectionChanged: (Set<_ViewMode> newSelection) {
                ref.read(_enterprisesViewModeProvider.notifier).setMode(newSelection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnterprisesTree(
    BuildContext context,
    WidgetRef ref,
    List<({Enterprise enterprise, bool isSubTenant})> combined,
  ) {
    if (combined.isEmpty) {
      return SliverToBoxAdapter(
        child: ActionableEmptyState(
          icon: Icons.business,
          title: 'Aucune entreprise',
          subtitle: 'Commencez par créer votre première entreprise',
          actionLabel: 'Créer une entreprise',
          onAction: () => EnterpriseActions.create(context, ref),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: ResponsiveHelper.adaptiveHorizontalPadding(context),
        child: Card(
          child: SizedBox(
            height: 600,
            child: EnterpriseTreeView(
              onEnterpriseSelected: (enterprise) {
                context.go('/modules/${enterprise.type.id}/${enterprise.id}');
              },
            ),
          ),
        ),
      ),
    );
  }

}
