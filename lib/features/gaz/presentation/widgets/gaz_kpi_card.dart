import 'package:flutter/material.dart';

/// KPI card générique pour le module gaz - remplace les variantes spécifiques.
class GazKpiCard extends StatelessWidget {
  const GazKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.valueColor,
    this.layout = GazKpiCardLayout.vertical,
    this.iconSize = 16,
    this.iconColor,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? valueColor;
  final GazKpiCardLayout layout;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: layout == GazKpiCardLayout.vertical
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: layout == GazKpiCardLayout.vertical
          ? _buildVerticalLayout(theme)
          : _buildHorizontalLayout(theme),
    );
  }

  Widget _buildVerticalLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Value and subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ?? theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Layout options for GazKpiCard.
enum GazKpiCardLayout {
  /// Vertical layout: title and icon on top, value and subtitle below.
  vertical,

  /// Horizontal layout: title/value on left, icon on right.
  horizontal,
}
