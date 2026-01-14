import 'package:flutter/material.dart';

/// KPI card for dashboard overview - matches Figma design.
class DashboardOverviewKpiCard extends StatelessWidget {
  const DashboardOverviewKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.valueColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
                width: 16,
                height: 16,
                child: Icon(icon, size: 16, color: const Color(0xFF4A5565)),
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
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF6A7282),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
