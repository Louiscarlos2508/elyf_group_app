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
          : const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF4A5565),
                ),
              ),
            ),
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? const Color(0xFF4A5565),
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.normal,
                color: valueColor ?? const Color(0xFF101828),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF6A7282),
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF4A5565),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                  color: valueColor ?? const Color(0xFF101828),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF6A7282),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          width: iconSize + 16,
          height: iconSize + 16,
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ?? const Color(0xFF3B82F6),
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

