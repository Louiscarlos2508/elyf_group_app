import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/enterprise.dart';
import '../../widgets/admin_shimmers.dart';

/// Section affichant la hiérarchie des entreprises (mère → sous-entreprises)
class AdminHierarchySection extends ConsumerWidget {
  const AdminHierarchySection({super.key});

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
                  'Hiérarchie des Entreprises',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vue arborescente: entreprise mère → sous-entreprises',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        enterprisesAsync.when(
          data: (enterprises) {
            // Séparer entreprises mères et sous-entreprises
            final parentEnterprises = enterprises
                .where((e) => e.parentEnterpriseId == null)
                .toList();
            final childEnterprises = enterprises
                .where((e) => e.parentEnterpriseId != null)
                .toList();

            if (parentEnterprises.isEmpty) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_tree,
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
                          'Créez une entreprise mère pour commencer',
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
                  final parent = parentEnterprises[index];
                  final children = childEnterprises
                      .where((c) => c.parentEnterpriseId == parent.id)
                      .toList();

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: _EnterpriseHierarchyCard(
                      parent: parent,
                      children: children,
                    ),
                  );
                },
                childCount: parentEnterprises.length,
              ),
            );
          },
          loading: () => SliverToBoxAdapter(
            child: AdminShimmers.enterpriseListShimmer(context),
          ),
          error: (error, stack) => SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
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

/// Card affichant une entreprise mère et ses sous-entreprises
class _EnterpriseHierarchyCard extends StatelessWidget {
  const _EnterpriseHierarchyCard({
    required this.parent,
    required this.children,
  });

  final Enterprise parent;
  final List<Enterprise> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Entreprise mère
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.business,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              parent.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Type: ${parent.type}'),
                if (parent.description != null)
                  Text(
                    parent.description!,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (children.isNotEmpty)
                  Chip(
                    label: Text('${children.length} sous-entreprise${children.length > 1 ? 's' : ''}'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(parent.isActive ? 'Active' : 'Inactive'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: parent.isActive
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
          ),

          // Sous-entreprises
          if (children.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.subdirectory_arrow_right,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sous-entreprises',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...children.map((child) => Padding(
                        padding: const EdgeInsets.only(left: 24, bottom: 8),
                        child: _ChildEnterpriseItem(child: child),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Item pour une sous-entreprise
class _ChildEnterpriseItem extends StatelessWidget {
  const _ChildEnterpriseItem({required this.child});

  final Enterprise child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.store,
            size: 20,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (child.description != null)
                  Text(
                    child.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Chip(
            label: Text(child.isActive ? 'Active' : 'Inactive'),
            visualDensity: VisualDensity.compact,
            backgroundColor: child.isActive
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}
