import 'package:flutter/material.dart';

class ImmobilierHeader extends StatelessWidget {
  const ImmobilierHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.gradientColors = const [Color(0xFF00BFA5), Color(0xFF00897B)], // Teal/Green default for Immobilier
    this.shadowColor,
    this.additionalActions,
    this.bottom,
    this.asSliver = true,
  });

  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color? shadowColor;
  final List<Widget>? additionalActions;
  final Widget? bottom;
  final bool asSliver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? gradientColors.last).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (additionalActions != null) ...[
                const SizedBox(width: 16),
                ...additionalActions!,
              ],
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: 24),
            bottom!,
          ],
        ],
      ),
    );

    if (asSliver) {
      return SliverToBoxAdapter(child: content);
    }
    return content;
  }
}
