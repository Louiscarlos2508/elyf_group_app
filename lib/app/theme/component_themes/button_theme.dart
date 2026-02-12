import 'package:flutter/material.dart';

FilledButtonThemeData buildFilledButtonTheme(ColorScheme colors) {
  return FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      minimumSize: const Size(64, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: colors.primary.withValues(alpha: 0.3),
    ),
  );
}

OutlinedButtonThemeData buildOutlinedButtonTheme(ColorScheme colors) {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: colors.primary,
      side: BorderSide(color: colors.primary.withValues(alpha: 0.5), width: 1.5),
      minimumSize: const Size(64, 54),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

TextButtonThemeData buildTextButtonTheme(ColorScheme colors) {
  return TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: colors.secondary,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}
