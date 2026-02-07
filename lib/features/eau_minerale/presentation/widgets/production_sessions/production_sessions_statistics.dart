import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                label: 'En Cours',
                value: sessionsEnCours.toString(),
                icon: Icons.timelapse,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
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
              child: _buildStatCard(
                context,
                label: 'Terminées',
                value: sessionsTerminees.toString(),
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
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
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return ElyfCard(
      isGlass: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
