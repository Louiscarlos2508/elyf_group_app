import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

import '../../../../../app/theme/app_theme.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/services/production_margin_calculator.dart';
import '../../screens/sections/production_tracking_screen.dart';

/// Composants réutilisables pour les cartes de sessions.
class ProductionSessionsCardComponents {
  /// Construit un chip de statut.
  static Widget buildStatusChip(
    BuildContext context,
    ProductionSessionStatus status,
  ) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<StatusColors>();

    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case ProductionSessionStatus.draft:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.edit_outlined;
        break;
      case ProductionSessionStatus.started:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        icon = Icons.play_circle_outline;
        break;
      case ProductionSessionStatus.inProgress:
        backgroundColor =
            statusColors?.success.withValues(alpha: 0.2) ??
            Colors.blue.withValues(alpha: 0.2);
        textColor = statusColors?.success ?? Colors.blue;
        icon = Icons.settings;
        break;
      case ProductionSessionStatus.suspended:
        backgroundColor =
            statusColors?.danger.withValues(alpha: 0.2) ??
            Colors.orange.withValues(alpha: 0.2);
        textColor = statusColors?.danger ?? Colors.orange;
        icon = Icons.pause_circle_outline;
        break;
      case ProductionSessionStatus.completed:
        backgroundColor =
            statusColors?.success.withValues(alpha: 0.2) ??
            Colors.green.withValues(alpha: 0.2);
        textColor = statusColors?.success ?? Colors.green;
        icon = Icons.check_circle;
        break;
      case ProductionSessionStatus.cancelled:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        icon = Icons.cancel_outlined;
        break;
    }

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  /// Construit la ligne d'informations (production, machines, bobines).
  static Widget buildInfoRow(BuildContext context, ProductionSession session) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              context,
              Icons.inventory_2,
              'Production',
              '${session.quantiteProduite.toStringAsFixed(0)} ${session.quantiteProduiteUnite}',
              theme.colorScheme.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildInfoItem(
              context,
              Icons.precision_manufacturing,
              'Machines',
              '${session.machinesUtilisees.length}',
              Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildInfoItem(
              context,
              Icons.rotate_right,
              'Bobines',
              '${session.bobinesUtilisees.length}',
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit les boutons d'action.
  /// Modifier est disponible dans l'écran Détail (action AppBar) et dans Suivi.
  static Widget buildActionButtons(
    BuildContext context,
    ProductionSession session,
  ) {
    return FilledButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                ProductionTrackingScreen(sessionId: session.id),
          ),
        );
      },
      icon: const Icon(Icons.track_changes, size: 18),
      label: const Text('Suivre'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(double.infinity, 0),
      ),
    );
  }

  /// Construit l'information de marge.
  static Widget buildMarginInfo(
    BuildContext context,
    ProductionSession session,
    List<Sale> ventes,
  ) {
    final theme = Theme.of(context);
    final marge = ProductionMarginCalculator.calculerMarge(
      session: session,
      ventesLiees: ventes,
    );
    final statusColors = Theme.of(context).extension<StatusColors>()!;
    final marginColor = marge.estRentable
        ? statusColors.success
        : statusColors.danger;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: marginColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: marginColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            marge.estRentable ? Icons.trending_up : Icons.trending_down,
            color: marginColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Marge: ${marge.pourcentageMargeFormate}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: marginColor,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
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
        ),
      ],
    );
  }
}
