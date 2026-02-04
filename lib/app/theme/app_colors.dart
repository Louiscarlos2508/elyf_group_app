import 'package:flutter/material.dart';

/// Tokens de couleurs centralisés pour l'application Elyf Groupe.
///
/// Ce fichier définit tous les tokens de couleur utilisés dans l'application.
/// Les couleurs sont organisées par sémantique (primitives, sémantiques, états).
class AppColors {
  const AppColors._();

  // ============================================================================
  // BRAND COLORS
  // ============================================================================

  /// Principal Blue - Professional & Trustworthy
  static const Color primary = Color(0xFF1B5E8D);
  static const Color primaryLight = Color(0xFF4B8AB8);
  static const Color primaryDark = Color(0xFF0F3D5E);

  /// Golden Accent - Premium & Quality
  static const Color accent = Color(0xFFFCCF4D);
  static const Color accentLight = Color(0xFFFDE08A);
  static const Color accentDark = Color(0xFFC7A13B);

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  static const Color success = Color(0xFF1BB57B);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFE94E77);
  static const Color info = Color(0xFF2196F3);

  // ============================================================================
  // NEUTRAL COLORS (Light Theme)
  // ============================================================================

  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color textBodyLight = Color(0xFF334155);
  static const Color textDisplayLight = Color(0xFF0F172A);
  static const Color borderLight = Color(0xFFE2E8F0);

  // ============================================================================
  // NEUTRAL COLORS (Dark Theme)
  // ============================================================================

  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textBodyDark = Color(0xFF94A3B8);
  static const Color textDisplayDark = Color(0xFFF8FAFC);
  static const Color borderDark = Color(0xFF334155);

  // ============================================================================
  // DEPRECATED / LEGACY (Keep for compatibility during refactoring)
  // ============================================================================
  static const Color seed = primary;
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE0E0E0);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral900 = Color(0xFF212121);
}
