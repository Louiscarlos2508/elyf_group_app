import 'package:flutter/material.dart';

/// Widget réutilisable pour les en-têtes de section dans les dashboards.
///
/// Assure une cohérence visuelle à travers toute l'application.
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
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, top, 24, bottom),
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
