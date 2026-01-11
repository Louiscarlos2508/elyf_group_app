import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Helpers pour améliorer l'accessibilité de l'application.
///
/// Fournit des utilitaires pour :
/// - Ajouter des semantics aux widgets
/// - Vérifier le contraste des couleurs
/// - Gérer le focus de manière accessible
class AccessibilityHelpers {
  const AccessibilityHelpers._();
}

/// Niveau de contraste WCAG 2.1.
enum ContrastLevel {
  /// Niveau AA (minimum requis) - 4.5:1 pour texte normal, 3:1 pour texte large
  aa,
  /// Niveau AAA (recommandé) - 7:1 pour texte normal, 4.5:1 pour texte large
  aaa,
}

/// Service pour vérifier le contraste des couleurs selon WCAG 2.1.
///
/// WCAG 2.1 définit les niveaux de contraste minimum :
/// - Niveau AA (minimum) : 4.5:1 pour texte normal, 3:1 pour texte large
/// - Niveau AAA (recommandé) : 7:1 pour texte normal, 4.5:1 pour texte large
class ContrastChecker {
  const ContrastChecker._();

  /// Calcule le ratio de contraste entre deux couleurs selon WCAG 2.1.
  ///
  /// Retourne un ratio entre 1 (même couleur) et 21 (contraste maximum).
  static double calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = _calculateRelativeLuminance(foreground);
    final bgLuminance = _calculateRelativeLuminance(background);

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calcule la luminance relative d'une couleur selon WCAG 2.1.
  static double _calculateRelativeLuminance(Color color) {
    final r = _linearizeColorComponent((color.r * 255.0).round().clamp(0, 255) / 255.0);
    final g = _linearizeColorComponent((color.g * 255.0).round().clamp(0, 255) / 255.0);
    final b = _linearizeColorComponent((color.b * 255.0).round().clamp(0, 255) / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linearise une composante de couleur pour le calcul de luminance.
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  /// Vérifie si le contraste entre deux couleurs respecte WCAG 2.1.
  ///
  /// [foreground] : Couleur du texte/élément
  /// [background] : Couleur de fond
  /// [isLargeText] : true si le texte est large (>= 18pt ou >= 14pt bold)
  /// [level] : Niveau WCAG requis (AA ou AAA)
  ///
  /// Retourne true si le contraste est suffisant.
  static bool meetsContrastRatio({
    required Color foreground,
    required Color background,
    bool isLargeText = false,
    ContrastLevel level = ContrastLevel.aa,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    
    switch (level) {
      case ContrastLevel.aa:
        return isLargeText ? ratio >= 3.0 : ratio >= 4.5;
      case ContrastLevel.aaa:
        return isLargeText ? ratio >= 4.5 : ratio >= 7.0;
    }
  }

  /// Trouve une couleur avec un contraste suffisant si la couleur actuelle ne respecte pas WCAG.
  ///
  /// [foreground] : Couleur du texte/élément à ajuster
  /// [background] : Couleur de fond
  /// [isLargeText] : true si le texte est large
  /// [level] : Niveau WCAG requis
  ///
  /// Retourne une couleur ajustée avec un meilleur contraste, ou null si déjà suffisant.
  static Color? adjustColorForContrast({
    required Color foreground,
    required Color background,
    bool isLargeText = false,
    ContrastLevel level = ContrastLevel.aa,
  }) {
    if (meetsContrastRatio(
      foreground: foreground,
      background: background,
      isLargeText: isLargeText,
      level: level,
    )) {
      return null; // Déjà suffisant
    }

    // Essayer d'assombrir ou d'éclaircir la couleur
    final bgLuminance = _calculateRelativeLuminance(background);

    // Si le fond est clair, assombrir le texte
    if (bgLuminance > 0.5) {
      return _darkenColor(foreground);
    } else {
      // Si le fond est sombre, éclaircir le texte
      return _lightenColor(foreground);
    }
  }

  static Color _darkenColor(Color color) {
    const factor = 0.7;
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    final a = (color.a * 255.0).round().clamp(0, 255);
    
    return Color.fromARGB(
      a,
      (r * factor).round(),
      (g * factor).round(),
      (b * factor).round(),
    );
  }

  static Color _lightenColor(Color color) {
    const factor = 1.3;
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    final a = (color.a * 255.0).round().clamp(0, 255);
    
    return Color.fromARGB(
      a,
      math.min(255, (r * factor).round()),
      math.min(255, (g * factor).round()),
      math.min(255, (b * factor).round()),
    );
  }
}

/// Helper pour créer des widgets avec semantics pour les lecteurs d'écran.
class AccessibleWidgets {
  const AccessibleWidgets._();

  /// Crée un bouton accessible avec semantics complètes.
  ///
  /// [label] : Label principal annoncé par le lecteur d'écran
  /// [hint] : Hint optionnel pour donner plus de contexte
  /// [onTap] : Callback appelé lors du tap
  /// [enabled] : Si le bouton est activé ou non
  /// [child] : Widget enfant
  static Widget accessibleButton({
    required String label,
    String? hint,
    required VoidCallback? onTap,
    bool enabled = true,
    required Widget child,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      enabled: enabled,
      button: true,
      child: child,
    );
  }

  /// Crée un champ de texte accessible.
  ///
  /// [label] : Label du champ (ex: "Adresse email")
  /// [hint] : Placeholder text
  /// [value] : Valeur actuelle du champ
  /// [error] : Message d'erreur à annoncer
  /// [required] : Si le champ est requis
  /// [obscured] : Si le texte est masqué (mot de passe)
  /// [child] : Widget TextField
  static Widget accessibleTextField({
    required String label,
    String? hint,
    String? value,
    String? error,
    bool required = false,
    bool obscured = false,
    required Widget child,
  }) {
    return Semantics(
      label: label + (required ? ' (requis)' : ''),
      hint: hint,
      value: value,
      textField: true,
      obscured: obscured,
      child: error != null
          ? Semantics(
              label: error,
              child: child,
            )
          : child,
    );
  }

  /// Crée une image accessible avec description.
  ///
  /// [image] : Widget Image
  /// [label] : Description de l'image pour le lecteur d'écran
  /// [excludeSemantics] : Si true, l'image est ignorée par le lecteur d'écran (décorative)
  static Widget accessibleImage({
    required Widget image,
    String? label,
    bool excludeSemantics = false,
  }) {
    if (excludeSemantics) {
      return ExcludeSemantics(child: image);
    }

    return Semantics(
      label: label ?? 'Image',
      image: true,
      child: image,
    );
  }

  /// Crée un conteneur scrollable accessible.
  ///
  /// [child] : Widget scrollable
  /// [label] : Label pour identifier la zone de scroll
  static Widget accessibleScrollable({
    required Widget child,
    String? label,
  }) {
    return Semantics(
      label: label,
      explicitChildNodes: true,
      child: child,
    );
  }

  /// Marque un widget comme en-tête pour la navigation.
  ///
  /// [level] : Niveau d'en-tête (1-6, comme HTML h1-h6)
  /// [child] : Widget texte/en-tête
  static Widget accessibleHeader({
    required int level,
    required Widget child,
  }) {
    assert(level >= 1 && level <= 6, 'Header level must be between 1 and 6');
    
    return Semantics(
      header: true,
      headingLevel: level,
      child: child,
    );
  }

  /// Crée un groupe sémantique pour regrouper des éléments liés.
  ///
  /// [label] : Label du groupe
  /// [child] : Widget contenant les éléments du groupe
  static Widget accessibleGroup({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      label: label,
      container: true,
      child: child,
    );
  }

  /// Marque un widget comme étant en état de chargement.
  ///
  /// [label] : Message à annoncer (ex: "Chargement en cours")
  /// [child] : Widget de chargement
  static Widget accessibleLoading({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: child,
    );
  }

  /// Crée une région live pour annoncer des changements dynamiques.
  ///
  /// Utilisé pour annoncer des changements importants (ex: notifications, erreurs).
  ///
  /// [label] : Message à annoncer
  /// [polite] : Si true, annonce de manière polie (n'interrompt pas), sinon assertive
  /// [child] : Widget enfant
  static Widget accessibleLiveRegion({
    required String label,
    bool polite = true,
    required Widget child,
  }) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: child,
    );
  }
}

/// Helper pour gérer le focus de manière accessible.
class FocusManager {
  /// Déplace le focus vers le prochain champ focusable.
  static void nextFocus(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Déplace le focus vers le champ précédent.
  static void previousFocus(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Déplace le focus vers un champ spécifique.
  static void requestFocus(BuildContext context, FocusNode node) {
    FocusScope.of(context).requestFocus(node);
  }

  /// Enlève le focus de tous les champs.
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Enlève le focus et cache le clavier.
  static void unfocusAndHideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
    // Sur mobile, cela cache automatiquement le clavier
  }

  /// Vérifie si un champ a actuellement le focus.
  static bool hasFocus(BuildContext context, FocusNode node) {
    return FocusScope.of(context).focusedChild == node;
  }

  /// Gère le focus lors de la soumission d'un formulaire.
  ///
  /// Si le focus actuel est le dernier champ, enlève le focus.
  /// Sinon, déplace le focus vers le prochain champ.
  static void handleFormSubmit(BuildContext context, {bool isLastField = false}) {
    if (isLastField) {
      unfocusAndHideKeyboard(context);
    } else {
      nextFocus(context);
    }
  }
}
