import 'package:flutter/material.dart';

import '../../shared/utils/accessibility_helpers.dart';

/// Extension du thème pour inclure des vérifications d'accessibilité.
extension AccessibilityThemeExtension on ThemeData {
  /// Vérifie si les couleurs du thème respectent les standards WCAG 2.1.
  ///
  /// Retourne une liste de problèmes d'accessibilité trouvés.
  List<String> checkAccessibility({
    ContrastLevel level = ContrastLevel.aa,
  }) {
    final issues = <String>[];

    // Vérifier le contraste texte principal / surface
    if (!ContrastChecker.meetsContrastRatio(
      foreground: colorScheme.onSurface,
      background: colorScheme.surface,
      level: level,
    )) {
      issues.add(
        'Contraste insuffisant entre onSurface et surface: '
        '${ContrastChecker.calculateContrastRatio(colorScheme.onSurface, colorScheme.surface).toStringAsFixed(2)}:1',
      );
    }

    // Vérifier le contraste texte primaire / surface
    if (!ContrastChecker.meetsContrastRatio(
      foreground: colorScheme.primary,
      background: colorScheme.surface,
      level: level,
    )) {
      issues.add(
        'Contraste insuffisant entre primary et surface: '
        '${ContrastChecker.calculateContrastRatio(colorScheme.primary, colorScheme.surface).toStringAsFixed(2)}:1',
      );
    }

    // Vérifier le contraste texte primaire / onPrimary
    if (!ContrastChecker.meetsContrastRatio(
      foreground: colorScheme.onPrimary,
      background: colorScheme.primary,
      level: level,
    )) {
      issues.add(
        'Contraste insuffisant entre onPrimary et primary: '
        '${ContrastChecker.calculateContrastRatio(colorScheme.onPrimary, colorScheme.primary).toStringAsFixed(2)}:1',
      );
    }

    // Vérifier le contraste texte erreur / surface
    if (!ContrastChecker.meetsContrastRatio(
      foreground: colorScheme.error,
      background: colorScheme.surface,
      level: level,
    )) {
      issues.add(
        'Contraste insuffisant entre error et surface: '
        '${ContrastChecker.calculateContrastRatio(colorScheme.error, colorScheme.surface).toStringAsFixed(2)}:1',
      );
    }

    // Vérifier le contraste texte onSurfaceVariant / surface
    if (!ContrastChecker.meetsContrastRatio(
      foreground: colorScheme.onSurfaceVariant,
      background: colorScheme.surface,
      isLargeText: true, // OnSurfaceVariant est souvent utilisé pour du texte secondaire
      level: level,
    )) {
      issues.add(
        'Contraste insuffisant entre onSurfaceVariant et surface: '
        '${ContrastChecker.calculateContrastRatio(colorScheme.onSurfaceVariant, colorScheme.surface).toStringAsFixed(2)}:1',
      );
    }

    return issues;
  }

  /// Obtient une couleur avec un contraste suffisant si nécessaire.
  ///
  /// Si la couleur actuelle respecte WCAG, retourne null.
  /// Sinon, retourne une couleur ajustée.
  Color? getAccessibleColor({
    required Color foreground,
    required Color background,
    bool isLargeText = false,
    ContrastLevel level = ContrastLevel.aa,
  }) {
    return ContrastChecker.adjustColorForContrast(
      foreground: foreground,
      background: background,
      isLargeText: isLargeText,
      level: level,
    );
  }
}

