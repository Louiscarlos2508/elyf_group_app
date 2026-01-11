import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import '../../../domain/entities/admin_module.dart';
import 'dialogs/module_details_dialog.dart';

/// Statistiques pour un module
class ModuleStats {
  const ModuleStats({
    required this.moduleId,
    required this.totalUsers,
    required this.totalEnterprises,
    required this.activeAssignments,
    required this.enterprises,
  });

  final String moduleId;
  final int totalUsers;
  final int totalEnterprises;
  final int activeAssignments;
  final List<dynamic> enterprises; // Enterprise list
}

/// Mapping entre les modules et les types d'entreprises
String? _getEnterpriseTypeForModule(String moduleId) {
  // Les modules correspondent généralement aux types d'entreprises
  final moduleToTypeMap = {
    'eau_minerale': 'eau_minerale',
    'gaz': 'gaz',
    'orange_money': 'orange_money',
    'immobilier': 'immobilier',
    'boutique': 'boutique',
  };
  return moduleToTypeMap[moduleId];
}

/// Provider pour récupérer les statistiques par module
final moduleStatsProvider = FutureProvider.family<ModuleStats, String>(
  (ref, moduleId) async {
    final enterpriseModuleUsers =
        await ref.watch(enterpriseModuleUsersProvider.future);
    final enterprises = await ref.watch(enterprisesProvider.future);

    final moduleAssignments =
        enterpriseModuleUsers.where((u) => u.moduleId == moduleId).toList();

    final uniqueUsers = moduleAssignments.map((a) => a.userId).toSet();
    final uniqueEnterprisesWithUsers =
        moduleAssignments.map((a) => a.enterpriseId).toSet();
    final activeAssignments =
        moduleAssignments.where((a) => a.isActive).length;

    // Récupérer toutes les entreprises qui correspondent au type du module
    final enterpriseType = _getEnterpriseTypeForModule(moduleId);
    final moduleEnterprises = enterpriseType != null
        ? enterprises.where((e) => e.type == enterpriseType).toList()
        : enterprises.where((e) => uniqueEnterprisesWithUsers.contains(e.id)).toList();

    return ModuleStats(
      moduleId: moduleId,
      totalUsers: uniqueUsers.length,
      totalEnterprises: moduleEnterprises.length,
      activeAssignments: activeAssignments,
      enterprises: moduleEnterprises,
    );
  },
);

/// Section pour gérer les modules
class AdminModulesSection extends ConsumerWidget {
  const AdminModulesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = AdminModules.all;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Modules'),
          floating: true,
          snap: true,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final module = modules[index];
                return _ModuleCard(
                  module: module,
                  onTap: () => _showModuleDetails(context, ref, module),
                );
              },
              childCount: modules.length,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showModuleDetails(
    BuildContext context,
    WidgetRef ref,
    AdminModule module,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => ModuleDetailsDialog(module: module),
    );
  }
}

/// Carte pour afficher un module avec ses statistiques
class _ModuleCard extends ConsumerWidget {
  const _ModuleCard({
    required this.module,
    required this.onTap,
  });

  final AdminModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(moduleStatsProvider(module.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIcon(module.icon),
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          module.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              statsAsync.when(
                data: (stats) => _StatsRow(stats: stats),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'home_work':
        return Icons.home_work;
      case 'storefront':
        return Icons.storefront;
      default:
        return Icons.business;
    }
  }
}

/// Ligne de statistiques pour un module
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final ModuleStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.people_outline,
            label: 'Utilisateurs',
            value: stats.totalUsers.toString(),
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatItem(
            icon: Icons.business_outlined,
            label: 'Entreprises',
            value: stats.totalEnterprises.toString(),
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatItem(
            icon: Icons.check_circle_outline,
            label: 'Actifs',
            value: stats.activeAssignments.toString(),
            color: theme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }
}

/// Item de statistique
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

