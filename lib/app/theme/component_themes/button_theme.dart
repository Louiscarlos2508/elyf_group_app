import 'package:flutter/material.dart';

FilledButtonThemeData buildFilledButtonTheme(ColorScheme colors) {
  return FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 6,
      shadowColor: colors.primary.withValues(alpha: 0.4),
    ),
  );
}

OutlinedButtonThemeData buildOutlinedButtonTheme(ColorScheme colors) {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: colors.primary,
      side: BorderSide(color: colors.primary, width: 1.4),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
