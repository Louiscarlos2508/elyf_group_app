import 'package:flutter/material.dart';

/// KPI card for wholesale sales tracking - matches Figma design.
class WholesaleKpiCard extends StatelessWidget {
  const WholesaleKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Row(
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
                    color: const Color(0xFF101828),
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
            width: 32,
            height: 32,
            child: Icon(
              icon,
              size: 32,
              color: iconColor ?? const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }
}

