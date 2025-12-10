import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/enterprise.dart';

/// Section pour gérer les entreprises
class AdminEnterprisesSection extends ConsumerWidget {
  const AdminEnterprisesSection({super.key});

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'eau_minerale':
        return Icons.water_drop_outlined;
      case 'gaz':
        return Icons.local_fire_department_outlined;
      case 'orange_money':
        return Icons.account_balance_wallet_outlined;
      case 'immobilier':
        return Icons.home_work_outlined;
      case 'boutique':
        return Icons.storefront_outlined;
      default:
        return Icons.business_outlined;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'eau_minerale':
        return 'Eau Minérale';
      case 'gaz':
        return 'Gaz';
      case 'orange_money':
        return 'Orange Money';
      case 'immobilier':
        return 'Immobilier';
      case 'boutique':
        return 'Boutique';
      default:
        return type;
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
              onPressed: () {
                // TODO: Show create enterprise dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Créer une entreprise - À implémenter'),
                  ),
                );
              },
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
                            _getTypeIcon(enterprise.type),
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
                                  label: Text(_getTypeLabel(enterprise.type)),
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
                              onPressed: () {
                                // TODO: Show edit dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Modifier ${enterprise.name} - À implémenter',
                                    ),
                                  ),
                                );
                              },
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

