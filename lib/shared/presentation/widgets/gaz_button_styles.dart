import 'package:flutter/material.dart';

/// Styles de boutons réutilisables pour le module gaz.
class GazButtonStyles {
  GazButtonStyles._();

  /// Style pour le bouton FilledButton principal.
  static ButtonStyle filledPrimary(BuildContext context) => FilledButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    minimumSize: const Size(0, 48),
    elevation: 0,
  );

  /// Style pour le bouton FilledButton avec icône.
  static ButtonStyle filledPrimaryIcon(BuildContext context) => FilledButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    minimumSize: const Size(0, 40),
    elevation: 0,
  );

  /// Style pour le bouton OutlinedButton standard.
  static ButtonStyle outlined(BuildContext context) => OutlinedButton.styleFrom(
    side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    minimumSize: const Size(0, 48),
    foregroundColor: Theme.of(context).colorScheme.onSurface,
  );

  /// Style pour le bouton OutlinedButton avec taille minimale personnalisée.
  static ButtonStyle outlinedWithMinSize(
    BuildContext context,
    double minWidth,
  ) => OutlinedButton.styleFrom(
    side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    minimumSize: Size(minWidth, 48),
    foregroundColor: Theme.of(context).colorScheme.onSurface,
  );
}
