import 'package:flutter/material.dart';

/// Tokens de couleurs centralisés pour l'application Elyf Groupe.
///
/// Ce fichier définit tous les tokens de couleur utilisés dans l'application.
/// Les couleurs sont organisées par sémantique (primitives, sémantiques, états).
class AppColors {
  const AppColors._();

  // ============================================================================
  // BRAND COLORS (Premium HSL Variants)
  // ============================================================================

  /// Principal Blue - Deep & Sophisticated
  static const Color primary = Color(0xFF0F4C75);
  static const Color primaryLight = Color(0xFF3282B8);
  static const Color primaryDark = Color(0xFF1B262C);

  /// Golden Accent - Vibrant & Premium
  static const Color accent = Color(0xFFFFD700);
  static const Color accentLight = Color(0xFFFFE066);
  static const Color accentDark = Color(0xFFCCAC00);

  // ============================================================================
  // SEMANTIC COLORS (Vibrant)
  // ============================================================================

  static const Color success = Color(0xFF00C897);
  static const Color warning = Color(0xFFFFB319);
  static const Color danger = Color(0xFFFF4D4D);
  static const Color info = Color(0xFF00A8FF);

  // ============================================================================
  // NEUTRAL COLORS (Light Theme - Soft & Clean)
  // ============================================================================

  static const Color bgLight = Color(0xFFF0F5F9);
  static const Color surfaceLight = Colors.white;
  static const Color textBodyLight = Color(0xFF52616B);
  static const Color textDisplayLight = Color(0xFF1B262C);
  static const Color borderLight = Color(0xFFE1E8EE);

  // ============================================================================
  // NEUTRAL COLORS (Dark Theme - Deep & Elegant)
  // ============================================================================

  static const Color bgDark = Color(0xFF0F111A);
  static const Color surfaceDark = Color(0xFF1A1D2B);
  static const Color textBodyDark = Color(0xFFA0AEC0);
  static const Color textDisplayDark = Color(0xFFF7FAFC);
  static const Color borderDark = Color(0xFF2D3748);

  // ============================================================================
  // PREMIUM EFFECTS (Gradients & Glassmorphism)
  // ============================================================================

  static final List<Color> mainGradient = [
    const Color(0xFF0F4C75),
    const Color(0xFF3282B8),
  ];

  static final List<Color> waterGradient = [
    const Color(0xFF00C2FF),
    const Color(0xFF00A8FF),
    const Color(0xFF007AFF),
  ];

  static final List<Color> orangeMoneyGradient = [
    const Color(0xFFFF6B00), // Deep Premium Orange
    const Color(0xFFFF9E00), // Vibrant Gold/Orange
    const Color(0xFFFFC300), // Soft Accent Gold
  ];

  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBlack = Color(0x1A000000);
  static const Color glassBorderWhite = Color(0x33FFFFFF);
  static const Color glassBorderBlack = Color(0x33000000);
}
