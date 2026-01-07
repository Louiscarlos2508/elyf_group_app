import 'package:flutter/material.dart';

import '../../../domain/entities/production_session_status.dart';

/// Composants réutilisables pour les rapports de production.
class ProductionReportComponents {
  /// Construit un titre de section.
  static Widget buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Construit un item d'information.
  static Widget buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une grille d'informations.
  static Widget buildInfoGrid({
    required List<({String label, String value, IconData icon})> items,
    required ThemeData theme,
  }) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items.map((item) => buildInfoItem(
        label: item.label,
        value: item.value,
        icon: item.icon,
        theme: theme,
      )).toList(),
    );
  }

  /// Construit un chip de statut.
  static Widget buildStatusChip({
    required ProductionSessionStatus status,
    required ThemeData theme,
  }) {
    final color = _getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une ligne de coût.
  static Widget buildCostRow({
    required String label,
    required int amount,
    required String Function(int) formatCurrency,
    required ThemeData theme,
    bool isTotal = false,
    bool isRevenue = false,
    bool isMargin = false,
    double? percentage,
  }) {
    Color color = theme.colorScheme.onSurface;
    
    if (isMargin) {
      color = amount >= 0 ? Colors.green.shade700 : Colors.red.shade700;
    } else if (isRevenue) {
      color = Colors.green.shade700;
    } else if (isTotal) {
      color = theme.colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCurrency(amount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal || isMargin ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
              if (percentage != null) ...[
                const SizedBox(width: 8),
                Text(
                  '(${percentage!.toStringAsFixed(1)}%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static Color _getStatusColor(ProductionSessionStatus status) {
    switch (status) {
      case ProductionSessionStatus.draft:
        return Colors.grey;
      case ProductionSessionStatus.started:
        return Colors.blue;
      case ProductionSessionStatus.inProgress:
        return Colors.green;
      case ProductionSessionStatus.suspended:
        return Colors.orange;
      case ProductionSessionStatus.completed:
        return Colors.green.shade700;
    }
  }

  static IconData _getStatusIcon(ProductionSessionStatus status) {
    switch (status) {
      case ProductionSessionStatus.draft:
        return Icons.edit_outlined;
      case ProductionSessionStatus.started:
        return Icons.play_circle_outline;
      case ProductionSessionStatus.inProgress:
        return Icons.sync;
      case ProductionSessionStatus.suspended:
        return Icons.pause_circle_outline;
      case ProductionSessionStatus.completed:
        return Icons.check_circle;
    }
  }
}

