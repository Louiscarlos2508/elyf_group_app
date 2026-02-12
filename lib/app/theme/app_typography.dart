import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme buildAppTextTheme(ColorScheme colors) {
  final base = ThemeData(textTheme: GoogleFonts.poppinsTextTheme()).textTheme;
  final displayBase = GoogleFonts.outfitTextTheme();
  
  final applied = base.apply(
    bodyColor: colors.onSurface,
    displayColor: colors.onSurface,
  );

  return applied.copyWith(
    displayLarge: displayBase.displayLarge?.copyWith(
      fontWeight: FontWeight.w900,
      color: colors.onSurface,
      letterSpacing: -2,
    ),
    headlineLarge: displayBase.headlineLarge?.copyWith(
      fontWeight: FontWeight.w900,
      color: colors.onSurface,
      letterSpacing: -1.5,
    ),
    headlineMedium: displayBase.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: colors.onSurface,
      letterSpacing: -1,
    ),
    headlineSmall: displayBase.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: colors.onSurface,
      letterSpacing: -0.5,
    ),
    titleLarge: displayBase.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: colors.onSurface,
    ),
    titleMedium: displayBase.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.onSurface,
    ),
    labelLarge: displayBase.labelLarge?.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w900,
      color: colors.onSurface,
    ),
    bodyLarge: applied.bodyLarge?.copyWith(
      height: 1.6,
      letterSpacing: 0.2,
    ),
  );
}
