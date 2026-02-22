import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
          // Decorative Circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activeEnterprise != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                activeEnterprise.name.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onPrimary,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (additionalActions != null || bottom != null) ...[
                  const SizedBox(height: 12),
                  if (additionalActions != null)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: additionalActions!.map((action) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: action,
                          );
                        }).toList(),
                      ),
                    ),
                  if (bottom != null) ...[
                    if (additionalActions != null) const SizedBox(height: 16),
                    bottom!,
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (asSliver) {
      return SliverToBoxAdapter(child: content);
    }
    return content;
  }
}

