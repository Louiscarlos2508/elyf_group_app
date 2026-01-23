import 'package:flutter/material.dart';

/// Cartes de statistiques des sessions de production.
class ProductionSessionsStatistics extends StatelessWidget {
  const ProductionSessionsStatistics({
    super.key,
    required this.totalSessions,
    required this.sessionsEnCours,
    required this.sessionsTerminees,
    required this.totalProduit,
  });

  final int totalSessions;
  final int sessionsEnCours;
  final int sessionsTerminees;
  final double totalProduit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile layout: Single row scrollable or Grid
        // Here we keep the 2x2 grid for standard mobile width as it offers good density
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'En Cours',
                    value: sessionsEnCours.toString(),
                    icon: Icons.timelapse,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Produits',
                    value: totalProduit.toInt().toString(),
                    icon: Icons.water_drop,
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Terminées',
                    value: sessionsTerminees.toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Total Sessions',
                    value: totalSessions.toString(),
                    icon: Icons.history,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Modern Flat Design
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
