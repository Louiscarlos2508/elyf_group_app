import 'package:flutter/material.dart';

/// Cellule de tableau pour les agents.
class AgentsTableCell {
  /// Construit un en-tête de colonne.
  static Widget buildHeader(
    String text,
    double width, {
    bool alignRight = false,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          width: width,
          padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            text.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
              fontFamily: 'Outfit',
            ),
          ),
        );
      },
    );
  }

  /// Construit une cellule de tableau.
  static Widget buildCell(
    dynamic content,
    double width, {
    bool alignRight = false,
    Color? color,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Align(
              alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
              child: content is Widget
                  ? content
                  : Text(
                      content.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color ?? theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Outfit',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        );
      },
    );
  }
}
