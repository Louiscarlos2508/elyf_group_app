import 'package:flutter/material.dart';

/// Tokens d'espacement centralisés pour l'application.
///
/// Assure une cohérence visuelle à travers tous les écrans.
class AppSpacing {
  const AppSpacing._();

  // ============================================================================
  // ESPACEMENTS STANDARDS
  // ============================================================================

  /// Espacement très petit (4px)
  static const double xs = 4.0;

  /// Espacement petit (8px)
  static const double sm = 8.0;

  /// Espacement moyen (16px)
  static const double md = 16.0;

  /// Espacement large (24px)
  static const double lg = 24.0;

  /// Espacement très large (32px)
  static const double xl = 32.0;

  /// Espacement extra large (48px)
  static const double xxl = 48.0;

  // ============================================================================
  // PADDING STANDARDS
  // ============================================================================

  /// Padding standard pour les écrans
  static const EdgeInsets screenPadding = EdgeInsets.all(24);

  /// Padding pour les sections
  static const EdgeInsets sectionPadding = EdgeInsets.fromLTRB(24, 8, 24, 24);

  /// Padding pour les cartes
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  /// Padding pour les dialogs
  static const EdgeInsets dialogPadding = EdgeInsets.all(24);

  /// Padding horizontal standard
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 24);

  /// Padding vertical standard
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: 16);

  // ============================================================================
  // MARGINS STANDARDS
  // ============================================================================

  /// Marge entre les sections
  static const EdgeInsets sectionMargin = EdgeInsets.only(bottom: 24);

  /// Marge entre les éléments d'une liste
  static const EdgeInsets listItemMargin = EdgeInsets.only(bottom: 8);

  // ============================================================================
  // HELPERS RESPONSIVE
  // ============================================================================

  /// Padding adaptatif selon la taille d'écran
  static EdgeInsets adaptivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return const EdgeInsets.all(16);
    } else if (width < 1024) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  /// Padding horizontal adaptatif
  static EdgeInsets adaptiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (width < 1024) {
      return const EdgeInsets.symmetric(horizontal: 20);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
  }
}
