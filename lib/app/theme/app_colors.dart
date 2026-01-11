import 'package:flutter/material.dart';

/// Tokens de couleurs centralisés pour l'application Elyf Groupe.
///
/// Ce fichier définit tous les tokens de couleur utilisés dans l'application.
/// Les couleurs sont organisées par sémantique (primitives, sémantiques, états).
class AppColors {
  const AppColors._();

  // ============================================================================
  // COULEURS PRIMITIVES (Seed colors)
  // ============================================================================

  /// Couleur primaire (seed) - Bleu principal de l'application
  /// Hex: #1B5E8D
  static const Color seed = Color(0xFF1B5E8D);

  /// Couleur d'accent - Jaune doré
  /// Hex: #FCCF4D
  static const Color accent = Color(0xFFFCCF4D);

  // ============================================================================
  // COULEURS SÉMANTIQUES (States)
  // ============================================================================

  /// Couleur de succès - Vert
  /// Hex: #1BB57B
  static const Color success = Color(0xFF1BB57B);

  /// Couleur de danger/erreur - Rouge/Rose
  /// Hex: #E94E77
  static const Color danger = Color(0xFFE94E77);

  /// Couleur d'avertissement - Orange (si nécessaire)
  /// Hex: #FF9800
  static const Color warning = Color(0xFFFF9800);

  /// Couleur d'information - Bleu clair (si nécessaire)
  /// Hex: #2196F3
  static const Color info = Color(0xFF2196F3);

  // ============================================================================
  // COULEURS NEUTRES (si nécessaire pour les thèmes personnalisés)
  // ============================================================================

  /// Gris très clair (backgrounds)
  static const Color neutral50 = Color(0xFFFAFAFA);

  /// Gris clair (dividers)
  static const Color neutral100 = Color(0xFFF5F5F5);

  /// Gris moyen (borders)
  static const Color neutral200 = Color(0xFFE0E0E0);

  /// Gris foncé (textes secondaires)
  static const Color neutral600 = Color(0xFF757575);

  /// Gris très foncé (textes principaux)
  static const Color neutral900 = Color(0xFF212121);
}
