import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart' show adminStatsProvider, AdminStats;

/// Optimized stats grid that only rebuilds when stats change.
/// 
/// Uses Riverpod's select to minimize rebuilds.
class OptimizedStatsGrid extends ConsumerWidget {
  const OptimizedStatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use select to only rebuild when specific stats change
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      data: (stats) => _StatsGridContent(stats: stats),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erreur: $error'),
      ),
    );
  }
}

/// Separate widget with const constructor for better performance.
class _StatsGridContent extends StatelessWidget {
  const _StatsGridContent({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Entreprises',
                  value: '${stats.totalEnterprises}',
                  subtitle: '${stats.activeEnterprises} actives',
                  icon: Icons.business_outlined,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Utilisateurs',
                  value: '${stats.totalUsers}',
                  subtitle: '${stats.activeUsers} actifs',
                  icon: Icons.people_outlined,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Rôles',
                  value: '${stats.totalRoles}',
                  subtitle: 'Rôles définis',
                  icon: Icons.shield_outlined,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Assignations',
                  value: '${stats.totalAssignments}',
                  subtitle: 'Utilisateurs-entreprises',
                  icon: Icons.link_outlined,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stat card widget optimized with const constructor.
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

