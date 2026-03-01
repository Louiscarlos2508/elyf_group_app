import 'package:flutter/material.dart';

CardThemeData buildCardTheme(ColorScheme colors) {
  return CardThemeData(
    elevation: 0, // Favoring subtle borders over shadows for premium look
    margin: EdgeInsets.zero,
    color: colors.surface,
    shadowColor: colors.primary.withValues(alpha: 0.05),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: colors.outline.withValues(alpha: 0.15)),
    ),
  );
}
