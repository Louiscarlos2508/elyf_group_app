import 'package:flutter/material.dart';

CardThemeData buildCardTheme(ColorScheme colors) {
  return CardThemeData(
    elevation: 8,
    margin: EdgeInsets.zero,
    color: colors.surface,
    shadowColor: Colors.black.withValues(alpha: 0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
  );
}
