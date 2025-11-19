import 'package:flutter/material.dart';

InputDecorationTheme buildInputTheme(ColorScheme colors) {
  return InputDecorationTheme(
    filled: true,
    fillColor: colors.surfaceContainerHigh.withValues(alpha: 0.6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: colors.primary, width: 1.4),
    ),
    labelStyle: TextStyle(color: colors.onSurfaceVariant),
  );
}
