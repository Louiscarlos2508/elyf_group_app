import 'package:flutter/material.dart';

class AppColors {
  // Light
  static const lightColorScheme = ColorScheme.light(
    primary:    Color(0xFF1565C0),
    secondary:  Color(0xFF42A5F5),
    surface:    Color(0xFFFFFFFF),
    background: Color(0xFFF5F7FA),
    error:      Color(0xFFC62828),
    onPrimary:   Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onSurface:   Color(0xFF1A1C1E),
    onBackground: Color(0xFF1A1C1E),
    onError:     Color(0xFFFFFFFF),
  );

  // Dark
  static const darkColorScheme = ColorScheme.dark(
    primary:    Color(0xFF42A5F5),
    secondary:  Color(0xFF90CAF9),
    surface:    Color(0xFF1E2230),
    background: Color(0xFF13161E),
    error:      Color(0xFFEF5350),
    onPrimary:   Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onSurface:   Color(0xFFE2E2E6),
    onBackground: Color(0xFFE2E2E6),
    onError:     Color(0xFFFFFFFF),
  );
}
