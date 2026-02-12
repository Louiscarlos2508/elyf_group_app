import 'package:flutter/material.dart';

/// Widget réutilisable pour les en-têtes de section dans les dashboards.
/// Version standard (RenderBox) pour utilisation dans Column, ListView, etc.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.top = 0,
    this.bottom = 8,
  });

  final String title;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(24, top + 12, 24, bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            width: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Version Sliver pour utilisation dans CustomScrollView.
class SliverSectionHeader extends StatelessWidget {
  const SliverSectionHeader({
    super.key,
    required this.title,
    this.top = 0,
    this.bottom = 8,
  });

  final String title;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SectionHeader(
        title: title,
        top: top,
        bottom: bottom,
      ),
    );
  }
}
