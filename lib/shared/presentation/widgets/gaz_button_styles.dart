import 'package:flutter/material.dart';

/// Styles de boutons réutilisables pour le module gaz.
class GazButtonStyles {
  GazButtonStyles._();

  /// Style pour le bouton FilledButton principal (noir).
  static ButtonStyle get filledPrimary => FilledButton.styleFrom(
    backgroundColor: const Color(0xFF030213),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    minimumSize: const Size(0, 36),
  );

  /// Style pour le bouton FilledButton avec icône (noir, padding réduit).
  static ButtonStyle get filledPrimaryIcon => FilledButton.styleFrom(
    backgroundColor: const Color(0xFF030213),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 9.99, vertical: 7.99),
    minimumSize: const Size(0, 32),
  );

  /// Style pour le bouton OutlinedButton standard.
  static ButtonStyle get outlined => OutlinedButton.styleFrom(
    side: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1.305),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 17.305, vertical: 9.305),
    minimumSize: const Size(0, 36),
  );

  /// Style pour le bouton OutlinedButton avec taille minimale personnalisée.
  static ButtonStyle outlinedWithMinSize(
    double minWidth,
  ) => OutlinedButton.styleFrom(
    side: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1.305),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 17.305, vertical: 9.305),
    minimumSize: Size(minWidth, 36),
  );
}
