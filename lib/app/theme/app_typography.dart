import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme buildAppTextTheme(ColorScheme colors) {
  final base = ThemeData(textTheme: GoogleFonts.poppinsTextTheme()).textTheme;
  final applied = base.apply(
    bodyColor: colors.onSurface,
    displayColor: colors.onSurface,
  );

  return applied.copyWith(
    displayLarge: applied.displayLarge?.copyWith(fontWeight: FontWeight.w700),
    headlineSmall: applied.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: applied.bodyLarge?.copyWith(height: 1.5),
    labelLarge: applied.labelLarge?.copyWith(
      letterSpacing: 0.5,
      fontWeight: FontWeight.w600,
    ),
  );
}
