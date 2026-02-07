import 'dart:ui';
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
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.7))
                    : theme.cardTheme.color ?? theme.colorScheme.surface),
        border: Border.all(
          color: borderColor ??
              (isGlass
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.4))
                  : theme.colorScheme.outline.withValues(alpha: 0.2)),
          width: 1,
        ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(ThemeData theme) {
    final isPositive = trend! >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          trendLabel ?? '${trend!.abs().toStringAsFixed(1)}%',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
