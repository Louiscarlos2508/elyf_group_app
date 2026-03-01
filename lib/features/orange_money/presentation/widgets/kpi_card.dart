import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

/// KPI card widget for displaying statistics.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconWidget,
    this.valueColor,
    this.backgroundColor,
    this.valueStyle,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? iconWidget;
  final Color? valueColor;
  final Color? backgroundColor;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ElyfCard(
      backgroundColor: backgroundColor,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null || iconWidget != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  iconWidget ??
                  Icon(
                    icon,
                    size: 28,
                    color: valueColor ?? theme.colorScheme.primary,
                  ),
            ),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontFamily: 'Outfit',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: valueStyle ??
                theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: valueColor ?? theme.colorScheme.onSurface,
                  fontFamily: 'Outfit',
                  fontSize: isMobile ? 20 : 24,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
