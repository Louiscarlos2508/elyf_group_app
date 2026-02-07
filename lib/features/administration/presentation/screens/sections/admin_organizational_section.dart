import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/enterprise.dart';
import '../../widgets/admin_shimmers.dart';
import '../../widgets/enterprises/enterprise_actions.dart';
import '../../widgets/enterprises/enterprise_list_item.dart';
import '../../widgets/enterprises/enterprise_empty_state.dart';
import '../../../../../shared/utils/responsive_helper.dart';

/// Section unifiée pour gérer les entreprises avec vue groupée par module
class AdminOrganizationalSection extends ConsumerStatefulWidget {
  const AdminOrganizationalSection({super.key});

  @override
  ConsumerState<AdminOrganizationalSection> createState() =>
      _AdminOrganizationalSectionState();
}

class _AdminOrganizationalSectionState
    extends ConsumerState<AdminOrganizationalSection> {
  // Map pour tracker quels modules sont expansés
  final Map<String, bool> _expandedModules = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enterprisesAsync = ref.watch(enterprisesProvider);

    return CustomScrollView(
      slivers: [
        // Premium Header with Banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Decorative background shapes
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.business_center,
                      size: 100,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  
                  // Header Content
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Organisation',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Structure et unités commerciales',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.add, color: theme.colorScheme.primary),
                                tooltip: 'Créer une entreprise',
                                onPressed: () => EnterpriseActions.create(context, ref),
                              ),
                            ),
                          ],
                        ),
                        
                        // Statistics Row
                        if (enterprisesAsync.hasValue) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _buildHeaderStat(
                                context,
                                label: 'Entreprises',
                                value: enterprisesAsync.value!.length.toString(),
                                icon: Icons.business,
                              ),
                              const SizedBox(width: 24),
                              _buildHeaderStat(
                                context,
                                label: 'Modules Activés',
                                value: enterprisesAsync.value!
                                    .map((e) => e.type.module.id)
                                    .toSet()
                                    .length
                                    .toString(),
                                icon: Icons.grid_view,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Contenu groupé par module
        enterprisesAsync.when(
          data: (enterprises) {
            if (enterprises.isEmpty) {
              return const SliverFillRemaining(
                child: EnterpriseEmptyState(),
              );
            }

            // Grouper par module
            final groupedByModule = <String, List<Enterprise>>{};
            for (final enterprise in enterprises) {
              final moduleKey = enterprise.type.module.id;
              groupedByModule.putIfAbsent(moduleKey, () => []).add(enterprise);
            }

            // Trier les modules (group en premier)
            final sortedModules = groupedByModule.keys.toList()
              ..sort((a, b) {
                if (a == 'group') return -1;
                if (b == 'group') return 1;
                return a.compareTo(b);
              });

            return SliverPadding(
              padding: ResponsiveHelper.adaptivePadding(context),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final moduleKey = sortedModules[index];
                    final moduleEnterprises = groupedByModule[moduleKey]!;
                    final module = moduleEnterprises.first.type.module;

                    // Séparer parents et enfants
                    final parents = moduleEnterprises
                        .where((e) => e.parentEnterpriseId == null)
                        .toList();
                    final children = moduleEnterprises
                        .where((e) => e.parentEnterpriseId != null)
                        .toList();

                    // Debug logging
                    developer.log(
                      '📦 Module: ${module.label}\n'
                      '   Total: ${moduleEnterprises.length}\n'
                      '   Parents: ${parents.length}\n'
                      '   Children: ${children.length}\n'
                      '   Children IDs: ${children.map((c) => '${c.name} (parent: ${c.parentEnterpriseId})').join(', ')}',
                      name: 'AdminOrganizationalSection',
                    );

                    // Initialiser l'état d'expansion si nécessaire
                    _expandedModules.putIfAbsent(moduleKey, () => true);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ModuleSection(
                        module: module,
                        parents: parents,
                        children: children,
                        isExpanded: _expandedModules[moduleKey]!,
                        onToggleExpanded: () {
                          setState(() {
                            _expandedModules[moduleKey] =
                                !_expandedModules[moduleKey]!;
                          });
                        },
                      ),
                    );
                  },
                  childCount: sortedModules.length,
                ),
              ),
            );
          },
          loading: () => SliverToBoxAdapter(
            child: AdminShimmers.enterpriseListShimmer(context),
          ),
          error: (error, stack) => SliverFillRemaining(
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

  Widget _buildHeaderStat(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 16, color: (color ?? Colors.white).withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color ?? Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: (color ?? Colors.white).withValues(alpha: 0.6),
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Section pour un module avec ses entreprises
class _ModuleSection extends ConsumerWidget {
  const _ModuleSection({
    required this.module,
    required this.parents,
    required this.children,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final dynamic module; // EnterpriseModule
  final List<Enterprise> parents;
  final List<Enterprise> children;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final moduleColor = module.color;
    final totalCount = parents.length + children.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: moduleColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // En-tête du module (toujours visible)
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: moduleColor.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: moduleColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      module.icon,
                      color: moduleColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module == EnterpriseModule.group
                              ? 'Administration & Groupe'
                              : module.label,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: moduleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalCount ${totalCount > 1 ? 'entreprises' : 'entreprise'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: moduleColor,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),

          // Contenu expansible
          if (isExpanded) ...[
            Divider(height: 1, color: moduleColor.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Afficher toutes les entreprises (parents et enfants)
                  ...parents.map((parent) {
                    final parentChildren = children
                        .where((c) => c.parentEnterpriseId == parent.id)
                        .toList();

                    if (parentChildren.isEmpty) {
                      // Entreprise sans enfants
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: EnterpriseListItem(
                          enterprise: parent,
                          isPointOfSale: false,
                          onViewDetails: () =>
                              EnterpriseActions.viewDetails(context, ref, parent),
                          onManageAccess: () {
                            context.go('/admin/enterprises/${parent.id}/access');
                          },
                          onEdit: () =>
                              EnterpriseActions.edit(context, ref, parent),
                          onDelete: () =>
                              EnterpriseActions.delete(context, ref, parent),
                          onToggleStatus: () =>
                              EnterpriseActions.toggleStatus(context, ref, parent),
                        ),
                      );
                    }

                    // Entreprise avec enfants - afficher avec hiérarchie
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _EnterpriseWithChildren(
                        parent: parent,
                        children: parentChildren,
                        moduleColor: moduleColor,
                      ),
                    );
                  }),

                  // Enfants orphelins (sans parent dans la liste)
                  ...children.where((c) {
                    return !parents.any((p) => p.id == c.parentEnterpriseId);
                  }).map((orphan) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EnterpriseListItem(
                        enterprise: orphan,
                        isPointOfSale: true,
                        onViewDetails: () =>
                            EnterpriseActions.viewDetails(context, ref, orphan),
                        onManageAccess: () {
                          context.go('/admin/enterprises/${orphan.id}/access');
                        },
                        onEdit: () =>
                            EnterpriseActions.edit(context, ref, orphan),
                        onDelete: () =>
                            EnterpriseActions.delete(context, ref, orphan),
                        onToggleStatus: () =>
                            EnterpriseActions.toggleStatus(context, ref, orphan),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget pour afficher une entreprise parent avec ses enfants
class _EnterpriseWithChildren extends ConsumerWidget {
  const _EnterpriseWithChildren({
    required this.parent,
    required this.children,
    required this.moduleColor,
  });

  final Enterprise parent;
  final List<Enterprise> children;
  final Color moduleColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: moduleColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Parent
          EnterpriseListItem(
            enterprise: parent,
            isPointOfSale: false,
            onViewDetails: () =>
                EnterpriseActions.viewDetails(context, ref, parent),
            onManageAccess: () {
              context.go('/admin/enterprises/${parent.id}/access');
            },
            onEdit: () => EnterpriseActions.edit(context, ref, parent),
            onDelete: () => EnterpriseActions.delete(context, ref, parent),
            onToggleStatus: () =>
                EnterpriseActions.toggleStatus(context, ref, parent),
          ),

          // Enfants
          Container(
            color: moduleColor.withValues(alpha: 0.03),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right,
                      size: 18,
                      color: moduleColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${children.length} ${children.length > 1 ? 'sites rattachés' : 'site rattaché'}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: moduleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...children.map((child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 24),
                    child: EnterpriseListItem(
                      enterprise: child,
                      isPointOfSale: true,
                      onViewDetails: () =>
                          EnterpriseActions.viewDetails(context, ref, child),
                      onManageAccess: () {
                        context.go('/admin/enterprises/${child.id}/access');
                      },
                      onEdit: () => EnterpriseActions.edit(context, ref, child),
                      onDelete: () =>
                          EnterpriseActions.delete(context, ref, child),
                      onToggleStatus: () =>
                          EnterpriseActions.toggleStatus(context, ref, child),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
