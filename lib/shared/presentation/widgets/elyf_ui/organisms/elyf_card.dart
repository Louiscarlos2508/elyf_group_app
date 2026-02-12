import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

/// Une carte premium avec support pour le glassmorphism et les dégradés.
class ElyfCard extends StatelessWidget {
  const ElyfCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin,
    this.borderRadius = 24,
    this.isGlass = false,
    this.gradient,
    this.borderColor,
    this.backgroundColor,
    this.elevation = 0,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isGlass;
  final Gradient? gradient;
  final Color? borderColor;
  final Color? backgroundColor;
  final double elevation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget current = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
        color: gradient != null
            ? null
            : backgroundColor ??
                (isGlass
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.85))
                    : theme.cardTheme.color ?? theme.colorScheme.surface),
        border: Border.all(
          color: borderColor ??
              (isGlass
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.5))
                  : theme.colorScheme.outline.withValues(alpha: 0.25)),
          width: 1,
        ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: (isDark ? Colors.black : theme.colorScheme.primary)
                      .withValues(alpha: 0.08),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation * 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      current = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: current,
      );
    }

    return current;
  }
}

/// Une carte de statistiques spécialisée pour les KPIs.
class ElyfStatsCard extends StatelessWidget {
  const ElyfStatsCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.trend,
    this.trendLabel,
    this.color,
    this.isGlass = true,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final double? trend; // Positive for up, negative for down
  final String? trendLabel;
  final Color? color;
  final bool isGlass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return ElyfCard(
      isGlass: isGlass,
      padding: const EdgeInsets.all(AppSpacing.md),
      elevation: isGlass ? 0 : 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon ?? Icons.analytics_outlined,
                  size: 20,
                  color: effectiveColor,
                ),
              ),
              if (trend != null)
                _buildTrendIndicator(theme),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(ThemeData theme) {
    final isPositive = trend! >= 0;
    final color = isPositive ? const Color(0xFF00C897) : const Color(0xFFFF4D4D);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            trendLabel ?? '${trend!.abs().toStringAsFixed(1)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
