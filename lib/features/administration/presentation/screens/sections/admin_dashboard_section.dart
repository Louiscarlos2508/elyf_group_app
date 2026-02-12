import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/atoms/elyf_shimmer.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import '../../widgets/admin_shimmers.dart';

/// Dashboard avec statistiques et vue d'ensemble
class AdminDashboardSection extends ConsumerWidget {
  const AdminDashboardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(adminStatsProvider);
    final enterprisesAsync = ref.watch(enterprisesProvider);
    final isSyncing = ref.watch(isAdminSyncingProvider).asData?.value ?? false;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                  theme.colorScheme.secondary.withValues(alpha: 0.2), // Subtle accent touch
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ADMINISTRATION',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tableau de bord',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    if (isSyncing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'SYNC',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Gérez votre réseau d\'entreprises et supervisez les accès système en temps réel.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        statsAsync.when(
          data: (stats) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElyfStatsCard(
                          label: 'Entreprises',
                          value: stats.totalEnterprises.toString(),
                          subtitle: '${stats.activeEnterprises} actives',
                          icon: Icons.business_center_rounded,
                          color: theme.colorScheme.primary,
                          isGlass: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElyfStatsCard(
                          label: 'Rôles',
                          value: stats.totalRoles.toString(),
                          subtitle: 'Définitions d\'accès',
                          icon: Icons.admin_panel_settings_rounded,
                          color: const Color(0xFF6366F1), // Deep Indigo
                          isGlass: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElyfStatsCard(
                          label: 'Utilisateurs',
                          value: stats.totalUsers.toString(),
                          subtitle: '${stats.activeUsers} actifs',
                          icon: Icons.account_circle_rounded,
                          color: const Color(0xFF00C897), // Success Emerald
                          isGlass: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElyfStatsCard(
                          label: 'Attributions',
                          value: stats.totalAssignments.toString(),
                          subtitle: 'Modules liés',
                          icon: Icons.hub_rounded,
                          color: theme.colorScheme.secondary,
                          isGlass: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          loading: () => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ElyfShimmer(child: ElyfShimmer.card(height: 200, borderRadius: 40)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: ElyfShimmer(child: ElyfShimmer.card(height: 120, borderRadius: 24))),
                      const SizedBox(width: 16),
                      Expanded(child: ElyfShimmer(child: ElyfShimmer.card(height: 120, borderRadius: 24))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          error: (error, stack) =>
              SliverToBoxAdapter(child: Center(child: Text('Erreur: $error'))),
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
              byType.putIfAbsent(enterprise.type.id, () => []).add(enterprise);
            }


            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final type = byType.keys.elementAt(index);
                final typeEnterprises = byType[type]!;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: ElyfCard(
                    isGlass: true,
                    padding: EdgeInsets.zero,
                    child: ExpansionTile(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      leading: Icon(
                        ref
                            .read(enterpriseTypeServiceProvider)
                            .getTypeIcon(type),
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        ref
                            .read(enterpriseTypeServiceProvider)
                            .getTypeLabel(type),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${typeEnterprises.length} entreprise${typeEnterprises.length > 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall,
                      ),
                      children: typeEnterprises.map<Widget>((enterprise) {
                        return ListTile(
                          title: Text(
                            enterprise.name,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            enterprise.description ?? '',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: enterprise.isActive
                                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              enterprise.isActive ? 'Active' : 'Inactive',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: enterprise.isActive
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }, childCount: byType.length),
            );
          },
          loading: () => SliverToBoxAdapter(
            child: AdminShimmers.enterpriseListShimmer(context),
          ),
          error: (error, stack) =>
              SliverToBoxAdapter(child: Center(child: Text('Erreur: $error'))),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}


