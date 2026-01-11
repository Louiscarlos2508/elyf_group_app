import 'package:flutter/material.dart';


/// Bouton accessible avec semantics complètes.
///
/// Utilise les semantics pour être compatible avec les lecteurs d'écran.
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.label,
    this.hint,
    required this.onPressed,
    this.enabled = true,
    required this.child,
    this.tooltip,
  });

  /// Label principal annoncé par le lecteur d'écran.
  final String label;

  /// Hint optionnel pour donner plus de contexte.
  final String? hint;

  /// Callback appelé lors du tap.
  final VoidCallback? onPressed;

  /// Si le bouton est activé ou non.
  final bool enabled;

  /// Widget enfant (généralement un Icon ou Text).
  final Widget child;

  /// Tooltip à afficher au survol (optionnel).
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = Semantics(
      label: label,
      hint: hint,
      enabled: enabled,
      button: true,
      child: child,
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Champ de texte accessible avec semantics complètes.
///
/// Wrapper pour TextFormField avec support complet des lecteurs d'écran.
class AccessibleTextField extends StatelessWidget {
  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    this.value,
    this.error,
    this.required = false,
    this.obscured = false,
    required this.child,
  });

  /// Label du champ (ex: "Adresse email").
  final String label;

  /// Placeholder text.
  final String? hint;

  /// Valeur actuelle du champ.
  final String? value;

  /// Message d'erreur à annoncer.
  final String? error;

  /// Si le champ est requis.
  final bool required;

  /// Si le texte est masqué (mot de passe).
  final bool obscured;

  /// Widget TextFormField enfant.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = required ? '$label (requis)' : label;

    Widget field = Semantics(
      label: semanticsLabel,
      hint: hint,
      value: value,
      textField: true,
      obscured: obscured,
      child: child,
    );

    if (error != null) {
      field = Semantics(
        label: '$semanticsLabel. Erreur: $error',
        child: field,
      );
    }

    return field;
  }
}

/// Image accessible avec description pour les lecteurs d'écran.
///
/// Si l'image est décorative (ex: icône sans signification), utilisez excludeSemantics: true.
class AccessibleImage extends StatelessWidget {
  const AccessibleImage({
    super.key,
    required this.image,
    this.label,
    this.excludeSemantics = false,
  });

  /// Widget Image.
  final Widget image;

  /// Description de l'image pour le lecteur d'écran.
  ///
  /// Si null et excludeSemantics est false, utilise "Image" par défaut.
  final String? label;

  /// Si true, l'image est ignorée par le lecteur d'écran (décorative).
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    if (excludeSemantics) {
      return ExcludeSemantics(child: image);
    }

    return Semantics(
      label: label ?? 'Image',
      image: true,
      child: image,
    );
  }
}

/// Zone scrollable accessible.
///
/// Wrapper pour les widgets scrollables avec semantics appropriées.
class AccessibleScrollable extends StatelessWidget {
  const AccessibleScrollable({
    super.key,
    required this.child,
    this.label,
    this.scrollDirection = Axis.vertical,
  });

  /// Widget scrollable enfant.
  final Widget child;

  /// Label pour identifier la zone de scroll.
  final String? label;

  /// Direction du scroll.
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      explicitChildNodes: true,
      child: child,
    );
  }
}

/// En-tête accessible pour la navigation.
///
/// Utilise les semantics de niveau d'en-tête (1-6) pour la navigation au clavier.
class AccessibleHeader extends StatelessWidget {
  const AccessibleHeader({
    super.key,
    required this.level,
    required this.child,
  });

  /// Niveau d'en-tête (1-6, comme HTML h1-h6).
  final int level;

  /// Widget texte/en-tête.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(level >= 1 && level <= 6, 'Header level must be between 1 and 6');
    
    return Semantics(
      header: true,
      headingLevel: level,
      child: child,
    );
  }
}

/// Groupe sémantique pour regrouper des éléments liés.
///
/// Utilisé pour créer des groupes logiques pour les lecteurs d'écran.
class AccessibleGroup extends StatelessWidget {
  const AccessibleGroup({
    super.key,
    required this.label,
    required this.child,
  });

  /// Label du groupe.
  final String label;

  /// Widget contenant les éléments du groupe.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      container: true,
      child: child,
    );
  }
}

/// Widget de chargement accessible.
///
/// Annonce l'état de chargement aux lecteurs d'écran.
class AccessibleLoading extends StatelessWidget {
  const AccessibleLoading({
    super.key,
    required this.label,
    required this.child,
  });

  /// Message à annoncer (ex: "Chargement en cours").
  final String label;

  /// Widget de chargement (généralement CircularProgressIndicator).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: child,
    );
  }
}

/// Région live pour annoncer des changements dynamiques.
///
/// Utilisé pour annoncer des changements importants (ex: notifications, erreurs).
/// Les changements sont annoncés automatiquement aux lecteurs d'écran.
class AccessibleLiveRegion extends StatelessWidget {
  const AccessibleLiveRegion({
    super.key,
    required this.label,
    this.polite = true,
    required this.child,
  });

  /// Message à annoncer.
  final String label;

  /// Si true, annonce de manière polie (n'interrompt pas), sinon assertive.
  final bool polite;

  /// Widget enfant.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: child,
    );
  }
}

/// Carte accessible avec semantics appropriées.
///
/// Wrapper pour Card avec support des lecteurs d'écran.
class AccessibleCard extends StatelessWidget {
  const AccessibleCard({
    super.key,
    required this.label,
    this.hint,
    this.onTap,
    this.selected = false,
    required this.child,
  });

  /// Label de la carte annoncé par le lecteur d'écran.
  final String label;

  /// Hint optionnel.
  final String? hint;

  /// Callback appelé lors du tap.
  final VoidCallback? onTap;

  /// Si la carte est sélectionnée.
  final bool selected;

  /// Contenu de la carte.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      selected: selected,
      button: onTap != null,
      onTap: onTap,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

