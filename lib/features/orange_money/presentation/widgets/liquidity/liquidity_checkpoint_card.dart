import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

/// Card widget displaying a single liquidity checkpoint (morning or evening).
class LiquidityCheckpointCard extends StatelessWidget {
  const LiquidityCheckpointCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.hasCheckpoint,
    this.cashAmount,
    this.simAmount,
    this.requiresJustification = false,
    this.discrepancyPercentage,
    required this.onPressed,
    this.onJustifyPressed,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool hasCheckpoint;
  final int? cashAmount;
  final int? simAmount;
  final bool requiresJustification;
  final double? discrepancyPercentage;
  final VoidCallback onPressed;
  final VoidCallback? onJustifyPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ElyfCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 20),
          _buildContent(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              fontFamily: 'Outfit',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasCheckpoint) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, 
                  size: 14, 
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Fait',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (hasCheckpoint && (cashAmount != null || simAmount != null)) {
      return _buildCheckpointDetails(theme);
    }
    return _buildEmptyState(theme);
  }

  Widget _buildCheckpointDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cashAmount != null) ...[
          _buildDetailRow('💵 Cash disponible', cashAmount!, theme, theme.colorScheme.onSurface),
          const SizedBox(height: 16),
        ],
        if (simAmount != null) ...[
          _buildDetailRow('📱 Solde SIM', simAmount!, theme, theme.colorScheme.primary),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Modifier le pointage'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (requiresJustification) ...[
          const SizedBox(height: 16),
          _buildJustificationRequired(theme),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, int amount, ThemeData theme, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatFCFA(amount),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: amountColor,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }

  Widget _buildJustificationRequired(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Écart de ${discrepancyPercentage?.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onJustifyPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Justifier l\'écart', 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Aucun pointage effectué pour cette période.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Faire le pointage'),
            style: ElevatedButton.styleFrom(
              backgroundColor: title.contains('Matin')
                  ? const Color(0xFFF54900)
                  : theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
