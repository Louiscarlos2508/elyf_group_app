import 'package:flutter/material.dart';

/// KPI card for stock overview - matches Figma design.
class StockKpiCard extends StatelessWidget {
  const StockKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.valueColor,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with icon
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: const Color(0xFF4A5565),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF4A5565),
                ),
              ),
            ],
          ),
          const SizedBox(height: 62),
          // Value
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.normal,
              color: valueColor ?? const Color(0xFF0A0A0A),
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
    );
  }
}

