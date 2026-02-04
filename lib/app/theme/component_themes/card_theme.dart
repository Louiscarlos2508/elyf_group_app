import 'package:flutter/material.dart';

CardThemeData buildCardTheme(ColorScheme colors) {
  return CardThemeData(
    elevation: 4,
    margin: EdgeInsets.zero,
    color: colors.surface,
    shadowColor: Colors.black.withValues(alpha: 0.05),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
    ),
  );
}
