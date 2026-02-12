import 'package:flutter/material.dart';

InputDecorationTheme buildInputTheme(ColorScheme colors) {
  final isLight = colors.brightness == Brightness.light;
  return InputDecorationTheme(
    filled: true,
    fillColor: isLight
        ? colors.surfaceContainerLow.withValues(alpha: 0.5)
        : colors.surfaceContainerLowest.withValues(alpha: 0.3),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.8), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: colors.error, width: 1),
    ),
    labelStyle: TextStyle(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: TextStyle(
      color: colors.primary,
      fontWeight: FontWeight.w600,
    ),
  );
}
