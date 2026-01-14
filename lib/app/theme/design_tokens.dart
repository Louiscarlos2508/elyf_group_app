import 'package:flutter/material.dart';

/// Design tokens centralisés pour l'application Elyf Groupe.
///
/// Ce fichier définit tous les tokens de design utilisés dans l'application :
/// - Espacement (spacing)
/// - Bordures et rayons (borders & radius)
/// - Ombres (elevations & shadows)
/// - Durées d'animation
/// - Tailles d'icônes
/// - Etc.
///
/// **Usage** :
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(AppSpacing.medium),
///   child: Container(
///     decoration: BoxDecoration(
///       borderRadius: BorderRadius.circular(AppRadius.medium),
///       boxShadow: [AppShadows.small],
///     ),
///   ),
/// )
/// ```
class DesignTokens {
  const DesignTokens._();
}

/// Tokens d'espacement pour une cohérence visuelle.
///
/// Basé sur une échelle de 4px (4, 8, 12, 16, 24, 32, 48, 64, 96).
class AppSpacing {
  const AppSpacing._();

  /// 0px - Pas d'espacement
  static const double none = 0.0;

  /// 4px - Espacement très petit (entre éléments très proches)
  static const double xxxs = 4.0;

  /// 8px - Espacement très petit (entre éléments liés)
  static const double xxs = 8.0;

  /// 12px - Espacement petit (entre éléments dans un groupe)
  static const double xs = 12.0;

  /// 16px - Espacement moyen-petit (espacement standard)
  static const double small = 16.0;

  /// 24px - Espacement moyen (espacement de section)
  static const double medium = 24.0;

  /// 32px - Espacement grand (espacement entre sections majeures)
  static const double large = 32.0;

  /// 48px - Espacement très grand (espacement de page)
  static const double xl = 48.0;

  /// 64px - Espacement extra grand (espacement de section majeure)
  static const double xxl = 64.0;

  /// 96px - Espacement maximum (espacement de layout)
  static const double xxxl = 96.0;

  /// Padding standard pour les cartes
  static const EdgeInsets cardPadding = EdgeInsets.all(medium);

  /// Padding standard pour les écrans
  static const EdgeInsets screenPadding = EdgeInsets.all(medium);

  /// Padding standard pour les dialogs
  static const EdgeInsets dialogPadding = EdgeInsets.all(large);

  /// Espacement horizontal standard
  static const EdgeInsets horizontalMedium = EdgeInsets.symmetric(
    horizontal: medium,
  );

  /// Espacement vertical standard
  static const EdgeInsets verticalMedium = EdgeInsets.symmetric(
    vertical: medium,
  );
}

/// Tokens de rayons de bordure pour une cohérence visuelle.
///
/// Basé sur des valeurs arrondies pour un look moderne.
class AppRadius {
  const AppRadius._();

  /// 4px - Rayon très petit (badges, chips)
  static const double xs = 4.0;

  /// 8px - Rayon petit (petits éléments)
  static const double small = 8.0;

  /// 12px - Rayon moyen (cartes, conteneurs standards)
  static const double medium = 12.0;

  /// 18px - Rayon grand (boutons, inputs)
  static const double large = 18.0;

  /// 24px - Rayon très grand (grandes cartes, dialogs)
  static const double xl = 24.0;

  /// 28px - Rayon extra grand (grands dialogs)
  static const double xxl = 28.0;

  /// 30px - Rayon pour chips (forme pill)
  static const double pill = 30.0;

  /// Rayon circulaire (100% - pour les boutons ronds)
  static const double circular = 1000.0;

  /// BorderRadius pour les cartes
  static const BorderRadius card = BorderRadius.all(Radius.circular(medium));

  /// BorderRadius pour les boutons
  static const BorderRadius button = BorderRadius.all(Radius.circular(large));

  /// BorderRadius pour les inputs
  static const BorderRadius input = BorderRadius.all(Radius.circular(large));

  /// BorderRadius pour les dialogs
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(xl));

  /// BorderRadius pour les chips
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
}

/// Tokens d'élévation et d'ombres.
///
/// Système d'élévation basé sur Material Design 3.
class AppElevation {
  const AppElevation._();

  /// 0 - Pas d'élévation (surfaces plates)
  static const double none = 0.0;

  /// 1 - Élévation très faible
  static const double xs = 1.0;

  /// 2 - Élévation faible (hover states)
  static const double small = 2.0;

  /// 4 - Élévation moyenne (cartes)
  static const double medium = 4.0;

  /// 6 - Élévation grande (boutons, éléments interactifs)
  static const double large = 6.0;

  /// 8 - Élévation très grande (dialogs)
  static const double xl = 8.0;

  /// 12 - Élévation maximum (modals)
  static const double xxl = 12.0;
}

/// Tokens d'ombres avec couleurs.
///
/// Ombres prédéfinies pour différents niveaux d'élévation.
class AppShadows {
  const AppShadows._();

  /// Ombre très petite (élévation xs)
  static List<BoxShadow> xs(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.1),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  /// Ombre petite (élévation small)
  static List<BoxShadow> small(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.15),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Ombre moyenne (élévation medium)
  static List<BoxShadow> medium(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Ombre grande (élévation large)
  static List<BoxShadow> large(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  /// Ombre très grande (élévation xl)
  static List<BoxShadow> xl(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Ombre avec couleur primaire pour les boutons
  static List<BoxShadow> primaryButton(Color primaryColor) => [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.4),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
}

/// Tokens de durées d'animation.
///
/// Durées standardisées pour les transitions et animations.
class AppDurations {
  const AppDurations._();

  /// 100ms - Animation très rapide (micro-interactions)
  static const Duration fastest = Duration(milliseconds: 100);

  /// 150ms - Animation rapide (hover states)
  static const Duration fast = Duration(milliseconds: 150);

  /// 200ms - Animation standard (transitions courantes)
  static const Duration standard = Duration(milliseconds: 200);

  /// 300ms - Animation moyenne (transitions modales)
  static const Duration medium = Duration(milliseconds: 300);

  /// 400ms - Animation lente (transitions de page)
  static const Duration slow = Duration(milliseconds: 400);

  /// 500ms - Animation très lente (animations complexes)
  static const Duration slowest = Duration(milliseconds: 500);
}

/// Courbes d'animation pour des transitions fluides.
class AppCurves {
  const AppCurves._();

  /// Courbe standard (ease-in-out)
  static const Curve standard = Curves.easeInOut;

  /// Courbe pour les entrées (ease-out)
  static const Curve enter = Curves.easeOut;

  /// Courbe pour les sorties (ease-in)
  static const Curve exit = Curves.easeIn;

  /// Courbe pour les rebonds (ease-out-back)
  static const Curve bounce = Curves.easeOutBack;

  /// Courbe pour les éléments élastiques (elastic-out)
  static const Curve elastic = Curves.elasticOut;
}

/// Tokens de tailles d'icônes.
///
/// Tailles standardisées pour les icônes dans l'application.
class AppIconSizes {
  const AppIconSizes._();

  /// 12px - Icône très petite
  static const double xs = 12.0;

  /// 16px - Icône petite
  static const double small = 16.0;

  /// 20px - Icône moyenne-petite
  static const double sm = 20.0;

  /// 24px - Icône standard (taille par défaut)
  static const double medium = 24.0;

  /// 32px - Icône grande
  static const double large = 32.0;

  /// 48px - Icône très grande (illustrations)
  static const double xl = 48.0;

  /// 64px - Icône extra grande (illustrations majeures)
  static const double xxl = 64.0;
}

/// Tokens de bordures.
///
/// Largeurs de bordure standardisées.
class AppBorders {
  const AppBorders._();

  /// 0.5px - Bordure très fine (dividers subtils)
  static const double thin = 0.5;

  /// 1px - Bordure fine (standard)
  static const double normal = 1.0;

  /// 1.4px - Bordure moyenne (boutons outlined)
  static const double medium = 1.4;

  /// 2px - Bordure épaisse (focus states)
  static const double thick = 2.0;

  /// 3px - Bordure très épaisse (emphasis)
  static const double xthick = 3.0;
}

/// Tokens de largeurs et hauteurs standard.
///
/// Dimensions standardisées pour les composants.
class AppSizes {
  const AppSizes._();

  /// Hauteur minimale pour les boutons
  static const double buttonHeight = 48.0;

  /// Hauteur minimale pour les boutons principaux (filled)
  static const double buttonHeightLarge = 52.0;

  /// Hauteur standard pour les inputs
  static const double inputHeight = 56.0;

  /// Largeur minimale pour les boutons
  static const double buttonMinWidth = 120.0;

  /// Largeur standard pour les dialogs
  static const double dialogWidth = 400.0;

  /// Largeur maximale pour les dialogs
  static const double dialogMaxWidth = 600.0;

  /// Largeur maximale pour le contenu des pages
  static const double contentMaxWidth = 1200.0;

  /// Breakpoint pour les layouts larges (desktop)
  static const double breakpointWide = 900.0;

  /// Breakpoint pour les layouts moyens (tablet)
  static const double breakpointMedium = 600.0;

  /// Breakpoint pour les layouts petits (mobile)
  static const double breakpointSmall = 360.0;
}

/// Tokens pour les opacités.
///
/// Valeurs d'opacité standardisées.
class AppOpacity {
  const AppOpacity._();

  /// 0.0 - Complètement transparent
  static const double transparent = 0.0;

  /// 0.05 - Très transparent (overlays subtils)
  static const double disabled = 0.05;

  /// 0.1 - Transparent (dividers, backgrounds subtils)
  static const double divider = 0.1;

  /// 0.15 - Légèrement transparent (hover states)
  static const double hover = 0.15;

  /// 0.2 - Transparent moyen (overlays)
  static const double overlay = 0.2;

  /// 0.38 - Transparent pour les textes désactivés
  static const double disabledText = 0.38;

  /// 0.4 - Transparent (shadows)
  static const double shadow = 0.4;

  /// 0.5 - Semi-transparent (disabled states)
  static const double disabledComponent = 0.5;

  /// 0.6 - Semi-transparent moyen
  static const double semiTransparent = 0.6;

  /// 0.87 - Presque opaque
  static const double nearlyOpaque = 0.87;

  /// 1.0 - Complètement opaque
  static const double opaque = 1.0;
}

/// Tokens pour les z-index (layers).
///
/// Ordre de superposition standardisé.
class AppLayers {
  const AppLayers._();

  /// -1 - Arrière-plan
  static const int background = -1;

  /// 0 - Niveau de base
  static const int base = 0;

  /// 1 - Éléments flottants légers
  static const int floating = 1;

  /// 10 - Dropdowns, tooltips
  static const int dropdown = 10;

  /// 20 - Sticky headers
  static const int sticky = 20;

  /// 30 - Overlays
  static const int overlay = 30;

  /// 40 - Dialogs
  static const int dialog = 40;

  /// 50 - Modals
  static const int modal = 50;

  /// 100 - Notifications toast
  static const int toast = 100;

  /// 1000 - Maximum (debug only)
  static const int maximum = 1000;
}
