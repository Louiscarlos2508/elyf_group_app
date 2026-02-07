import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/atoms/elyf_shimmer.dart';
import '../../../domain/entities/admin_module.dart';
import '../../../domain/entities/enterprise.dart';
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


/// Provider pour récupérer les statistiques par module
final moduleStatsProvider = FutureProvider.family<ModuleStats, String>((
  ref,
  moduleId,
) async {
  final enterpriseModuleUsers = await ref.watch(
    enterpriseModuleUsersProvider.future,
  );
  final enterprises = await ref.watch(enterprisesProvider.future);

  // Filtrer les utilisateurs assignés à ce module
  final moduleAssignments = enterpriseModuleUsers
      .where((u) => u.moduleId == moduleId)
      .toList();

  final uniqueUsers = moduleAssignments.map((a) => a.userId).toSet();
  final activeAssignments = moduleAssignments.where((a) => a.isActive).length;

  // Récupérer toutes les entreprises qui appartiennent à ce module métier
  final moduleEnterprises = enterprises.where((e) => e.type.module.id == moduleId).toList();

  return ModuleStats(
    moduleId: moduleId,
    totalUsers: uniqueUsers.length,
    totalEnterprises: moduleEnterprises.length,
    activeAssignments: activeAssignments,
    enterprises: moduleEnterprises,
  );
});

/// Section pour gérer les modules
class AdminModulesSection extends ConsumerWidget {
  const AdminModulesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final modules = AdminModules.all;
    final enterpriseModuleUsersAsync = ref.watch(enterpriseModuleUsersProvider);

    return CustomScrollView(
      slivers: [
        // Header Premium
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
                  // Formes décoratives
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -10,
                    child: Icon(
                      Icons.apps,
                      size: 100,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modules',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vue d\'ensemble et configurations des modules actifs.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        if (enterpriseModuleUsersAsync.hasValue) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _buildHeaderStat(
                                context,
                                label: 'Utilisateurs',
                                value: enterpriseModuleUsersAsync.value!
                                    .map((u) => u.userId)
                                    .toSet()
                                    .length
                                    .toString(),
                                icon: Icons.people_outline,
                              ),
                              const SizedBox(width: 24),
                              _buildHeaderStat(
                                context,
                                label: 'Configurations',
                                value: modules.length.toString(),
                                icon: Icons.settings_input_component,
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
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final module = modules[index];
              return _ModuleCard(
                module: module,
                onTap: () => _showModuleDetails(context, ref, module),
              );
            }, childCount: modules.length),
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
        Icon(icon, size: 16, color: (color ?? Colors.white).withValues(alpha: 0.7)),
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
  const _ModuleCard({required this.module, required this.onTap});

  final AdminModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(moduleStatsProvider(module.id));
    
    // Récupérer le module métier pour les couleurs et icônes
    final entModule = EnterpriseModule.values.firstWhere(
      (m) => m.id == module.id,
      orElse: () => EnterpriseModule.group,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElyfCard(
        isGlass: true,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: entModule.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        entModule.icon,
                        color: entModule.color,
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
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            module.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                statsAsync.when(
                  data: (stats) => _StatsRow(stats: stats, moduleColor: entModule.color),
                  loading: () => ElyfShimmer(
                    child: SizedBox(
                      height: 60,
                      child: Row(
                        children: [
                          Expanded(child: ElyfShimmer.card(height: 60, borderRadius: 12)),
                          const SizedBox(width: 12),
                          Expanded(child: ElyfShimmer.card(height: 60, borderRadius: 12)),
                          const SizedBox(width: 12),
                          Expanded(child: ElyfShimmer.card(height: 60, borderRadius: 12)),
                        ],
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne de statistiques pour un module
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.moduleColor});

  final ModuleStats stats;
  final Color moduleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.people_outline,
            label: 'Utilisateurs',
            value: stats.totalUsers.toString(),
            color: moduleColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatItem(
            icon: Icons.business_outlined,
            label: 'Entreprises',
            value: stats.totalEnterprises.toString(),
            color: moduleColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatItem(
            icon: Icons.check_circle_outline,
            label: 'Actifs',
            value: stats.activeAssignments.toString(),
            color: moduleColor,
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
