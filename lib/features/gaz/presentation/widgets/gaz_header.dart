import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/tenant/tenant_provider.dart';

/// A premium header widget for the Gaz module, following the project's standardized design.
class GazHeader extends ConsumerWidget {
  const GazHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.gradientColors = const [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Blue default for Gaz
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;

    final content = Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors.first,
            const Color(0xFF60A5FA), // Lighter blue for depth
            gradientColors.last,
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? gradientColors.last).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activeEnterprise?.name.toUpperCase() ?? title.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
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
