import 'package:flutter/material.dart';

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

    return Card(
      color: backgroundColor ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.22,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null || iconWidget != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: iconWidget ??
                    Icon(
                      icon,
                      size: 32,
                      color: valueColor ?? theme.colorScheme.primary,
                    ),
              ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4A5565),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: valueStyle ??
                  TextStyle(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? const Color(0xFF101828),
                    fontSize: isMobile ? 18 : 24,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

