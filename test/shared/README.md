# Tests Shared Components

Tests pour les composants et utilitaires partagés de l'application.

## Structure

```
test/shared/
├── utils/
│   └── responsive_helper_test.dart       # Tests pour ResponsiveHelper
└── presentation/
    └── widgets/
        ├── adaptive_navigation_scaffold_test.dart  # Tests pour AdaptiveNavigationScaffold
        └── responsive_layout_test.dart            # Tests d'intégration responsive
```

## ResponsiveHelper Tests

**Fichier**: `test/shared/utils/responsive_helper_test.dart`

Tests complets pour toutes les méthodes de `ResponsiveHelper` :

- ✅ Détection des breakpoints (mobile/tablet/desktop)
- ✅ Valeurs limites des breakpoints (599px, 600px, 1024px)
- ✅ Méthodes utilitaires (screenWidth, screenHeight)
- ✅ Padding adaptatif (mobile/tablet/desktop)
- ✅ Padding horizontal adaptatif
- ✅ Nombre de colonnes pour les grilles adaptatives

**Breakpoints testés** :
- Mobile : < 600px
- Tablet : 600px - 1023px
- Desktop : >= 1024px
- Extended : >= 800px

**Valeurs de padding testées** :
- Mobile : 16px
- Tablet : 20px
- Desktop : 24px

**Colonnes de grille testées** :
- Mobile : 1 colonne
- Tablet : 2 colonnes
- Desktop : 3 colonnes

## AdaptiveNavigationScaffold Tests

**Fichier**: `test/shared/presentation/widgets/adaptive_navigation_scaffold_test.dart`

Tests pour le comportement responsive du scaffold :

- ✅ Affichage du drawer sur mobile (< 600px)
- ✅ Affichage du NavigationRail sur tablette (600px - 1023px)
- ✅ Affichage du NavigationRail sur desktop (>= 1024px)
- ✅ Mode étendu du NavigationRail sur écrans larges (>= 800px)
- ✅ Changement de contenu lors de la sélection d'une section
- ✅ Affichage du widget de chargement
- ✅ Mise en cache des widgets pour les performances
- ✅ Titre de l'AppBar correct sur toutes les tailles d'écran

**Comportements testés** :
- Mobile : Drawer avec menu hamburger
- Tablet : NavigationRail compact (80px) avec labels sélectionnés
- Desktop étroit : NavigationRail compact
- Desktop large : NavigationRail étendu (200px) sans labels

## Responsive Layout Integration Tests

**Fichier**: `test/shared/presentation/widgets/responsive_layout_test.dart`

Tests d'intégration pour les layouts responsive :

- ✅ Padding adaptatif respecte les breakpoints
- ✅ Grilles adaptatives (colonnes selon la taille d'écran)
- ✅ Design tokens fonctionnent avec les layouts responsive
- ✅ LayoutBuilder fournit les bonnes contraintes
- ✅ Alignement des breakpoints avec les design tokens

## Exécution des tests

Pour exécuter tous les tests responsive :

```bash
# Tous les tests responsive
flutter test test/shared/

# Test spécifique
flutter test test/shared/utils/responsive_helper_test.dart
flutter test test/shared/presentation/widgets/adaptive_navigation_scaffold_test.dart
flutter test test/shared/presentation/widgets/responsive_layout_test.dart
```

## Couverture

**ResponsiveHelper** : 100% de couverture
- 19 tests couvrant toutes les méthodes et breakpoints

**AdaptiveNavigationScaffold** : Couverture des scénarios principaux
- 8 tests couvrant les comportements responsive principaux

**Responsive Layout** : Tests d'intégration
- 5 tests vérifiant l'intégration avec les design tokens

## Notes

- Les tests utilisent `MediaQuery` pour simuler différentes tailles d'écran
- Les tests sont indépendants et peuvent s'exécuter dans n'importe quel ordre
- Tous les breakpoints critiques sont testés (limites incluses)

## Maintenance

Lors de l'ajout de nouvelles fonctionnalités responsive :

1. Ajouter des tests pour les nouveaux breakpoints
2. Vérifier que les tests existants passent toujours
3. Documenter les nouveaux comportements dans ce README
4. Mettre à jour les tests si les breakpoints changent

