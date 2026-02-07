import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Un wrapper de shimmer haut de gamme avec des configurations pré-définies.
///
/// Suit les spécifications UX Premium pour Elyf Groupe.
class ElyfShimmer extends StatelessWidget {
  const ElyfShimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  final Widget child;
  final bool enabled;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBaseColor = baseColor ??
        (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final effectiveHighlightColor = highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return Shimmer.fromColors(
      baseColor: effectiveBaseColor,
      highlightColor: effectiveHighlightColor,
      period: duration,
      child: child,
    );
  }

  /// Préréglage pour une carte rectangulaire avec coins arrondis.
  static Widget card({
    double height = 120,
    double width = double.infinity,
    double borderRadius = 16,
    EdgeInsets? margin,
  }) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// Préréglage pour un cercle (ex: avatar).
  static Widget circle({double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Préréglage pour une ligne de texte.
  static Widget textLine({
    double height = 14,
    double width = double.infinity,
    double borderRadius = 4,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// Préréglage pour une ligne d'élément de liste complexe.
  static Widget listTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          circle(size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textLine(height: 16, width: double.infinity),
                const SizedBox(height: 8),
                textLine(height: 12, width: 150),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
