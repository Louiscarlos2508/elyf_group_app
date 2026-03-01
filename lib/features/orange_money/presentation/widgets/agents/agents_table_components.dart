import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/agent.dart';
import '../../../domain/entities/orange_money_enterprise_extensions.dart';
import '../../../../administration/domain/entities/enterprise.dart';

/// Composants réutilisables pour le tableau des agents (Entreprises Mobile Money).
class AgentsTableComponents {
  /// Construit la cellule du nom de l'agent.
  static Widget buildAgentNameCell(Enterprise agent) {
    // Utiliser le seuil critique défini dans les métadonnées ou 50000 par défaut
    final threshold = agent.metadata['criticalThreshold'] as int? ?? 50000;
    final balance = agent.floatBalance ?? 0;
    final isLowLiquidity = balance <= threshold;
    
    final dateFormat = DateFormat('d/M/yyyy');
    final dateStr = agent.createdAt != null
        ? dateFormat.format(agent.createdAt!)
        : 'N/A';

    return _buildNameCell(
      name: agent.name,
      subtitle: agent.type.label,
      dateStr: dateStr,
      isLowLiquidity: isLowLiquidity,
      isMain: agent.type.isMain,
    );
  }

  /// Construit la cellule du nom pour un compte agent (SIM).
  static Widget buildAgentAccountNameCell(Agent agent) {
    final isLowLiquidity = agent.isLowLiquidity(50000);
    
    final dateFormat = DateFormat('d/M/yyyy');
    final dateStr = agent.createdAt != null
        ? dateFormat.format(agent.createdAt!)
        : 'N/A';

    return _buildNameCell(
      name: agent.name,
      subtitle: 'Compte Agent',
      dateStr: dateStr,
      isLowLiquidity: isLowLiquidity,
      isMain: false,
    );
  }

  static Widget _buildNameCell({
    required String name,
    required String subtitle,
    required String dateStr,
    required bool isLowLiquidity,
    required bool isMain,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return SizedBox(
          width: 180, // standardized width
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'Outfit',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isLowLiquidity)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMain
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.colorScheme.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isMain
                              ? theme.colorScheme.primary.withValues(alpha: 0.2)
                              : theme.colorScheme.tertiary.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isMain
                              ? theme.colorScheme.primary
                              : theme.colorScheme.tertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontFamily: 'Outfit',
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construit le badge de l'opérateur.
  static Widget buildOperatorBadge(String? operatorName) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final label = operatorName ?? 'Non défini';
        
        return Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                fontFamily: 'Outfit',
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construit le chip de statut.
  static Widget buildStatusChip(bool isActive) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: isActive 
                ? theme.colorScheme.primaryContainer 
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border.all(
              color: isActive 
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              isActive ? 'ACTIF' : 'INACTIF',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                fontFamily: 'Outfit',
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construit la cellule d'actions.
  static Widget buildActionsCell({
    required VoidCallback onView,
    VoidCallback? onRefresh,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required double width,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 8,
              top: 10.61,
              right: 8,
              bottom: 10.61,
            ),
            child: Row(
              children: [
                _buildActionButton(icon: Icons.visibility, onPressed: onView),
                const SizedBox(width: 4),
                if (onRefresh != null) ...[
                  _buildActionButton(icon: Icons.refresh, onPressed: onRefresh),
                  const SizedBox(width: 4),
                ],
                _buildActionButton(icon: Icons.edit, onPressed: onEdit),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: Icons.close,
                  color: theme.colorScheme.error,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(10),
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: color ?? theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
