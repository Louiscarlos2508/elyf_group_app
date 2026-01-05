import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/enterprise.dart';

/// Dashboard avec statistiques et vue d'ensemble
class AdminDashboardSection extends ConsumerWidget {
  const AdminDashboardSection({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(adminStatsProvider);
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
                  'Tableau de bord',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vue d\'ensemble du système d\'administration',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        statsAsync.when(
          data: (stats) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Entreprises',
                      value: stats.totalEnterprises.toString(),
                      subtitle: '${stats.activeEnterprises} actives',
                      icon: Icons.business,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Rôles',
                      value: stats.totalRoles.toString(),
                      subtitle: 'Rôles définis',
                      icon: Icons.shield,
                      color: theme.colorScheme.secondary,
                    ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Utilisateurs',
                          value: stats.totalUsers.toString(),
                          subtitle: '${stats.activeUsers} actifs',
                          icon: Icons.people,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Attributions',
                          value: stats.totalAssignments.toString(),
                          subtitle: 'Accès entreprises/modules',
                          icon: Icons.link,
                          color: theme.colorScheme.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverToBoxAdapter(
            child: Center(
              child: Text('Erreur: $error'),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Entreprises par type',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        enterprisesAsync.when(
          data: (enterprises) {
            final byType = <String, List<Enterprise>>{};
            for (final enterprise in enterprises) {
              byType.putIfAbsent(enterprise.type, () => []).add(enterprise);
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final type = byType.keys.elementAt(index);
                  final typeEnterprises = byType[type]!;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Card(
                      child: ExpansionTile(
                        leading: Icon(
                          _getTypeIcon(type),
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          _getTypeLabel(type),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${typeEnterprises.length} entreprise${typeEnterprises.length > 1 ? 's' : ''}',
                        ),
                        children: typeEnterprises.map((enterprise) {
                          return ListTile(
                            title: Text(enterprise.name),
                            subtitle: Text(enterprise.description ?? ''),
                            trailing: enterprise.isActive
                                ? Chip(
                                    label: const Text('Active'),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                  )
                                : Chip(
                                    label: const Text('Inactive'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                childCount: byType.length,
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverToBoxAdapter(
            child: Center(
              child: Text('Erreur: $error'),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

