# Design Tokens - Documentation

## Vue d'ensemble

Ce fichier définit tous les **design tokens** utilisés dans l'application Elyf Groupe. Les design tokens sont des valeurs atomiques qui définissent l'identité visuelle de l'application (couleurs, espacements, typographie, etc.).

## Structure

Les design tokens sont organisés en classes statiques :

- `AppSpacing` - Espacements (padding, margin)
- `AppRadius` - Rayons de bordure (border-radius)
- `AppElevation` - Niveaux d'élévation
- `AppShadows` - Ombres avec couleurs
- `AppDurations` - Durées d'animation
- `AppCurves` - Courbes d'animation
- `AppIconSizes` - Tailles d'icônes
- `AppBorders` - Largeurs de bordures
- `AppSizes` - Dimensions standard (hauteurs, largeurs)
- `AppOpacity` - Valeurs d'opacité
- `AppLayers` - Z-index (ordre de superposition)

## Usage

### Espacement (Spacing)

```dart
// Au lieu de :
Padding(padding: EdgeInsets.all(24))

// Utilisez :
Padding(padding: EdgeInsets.all(AppSpacing.medium))

// Ou pour des valeurs prédéfinies :
Padding(padding: AppSpacing.cardPadding)
Padding(padding: AppSpacing.screenPadding)
```

### Rayons de bordure (Radius)

```dart
// Au lieu de :
BorderRadius.circular(12)

// Utilisez :
BorderRadius.circular(AppRadius.medium)

// Ou pour des valeurs prédéfinies :
decoration: BoxDecoration(
  borderRadius: AppRadius.card,
)
```

### Ombres (Shadows)

```dart
// Au lieu de :
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.2),
    blurRadius: 8,
    offset: Offset(0, 4),
  ),
]

// Utilisez :
decoration: BoxDecoration(
  boxShadow: AppShadows.medium(Colors.black),
)
```

### Animations

```dart
// Au lieu de :
Duration(milliseconds: 300)

// Utilisez :
AnimationController(
  duration: AppDurations.medium,
  vsync: this,
)

// Avec courbes :
AnimatedContainer(
  duration: AppDurations.standard,
  curve: AppCurves.enter,
)
```

### Tailles d'icônes

```dart
// Au lieu de :
Icon(Icons.add, size: 24)

// Utilisez :
Icon(Icons.add, size: AppIconSizes.medium)
```

### Dimensions

```dart
// Au lieu de :
SizedBox(height: 48)

// Utilisez :
SizedBox(height: AppSizes.buttonHeight)
```

## Échelle d'espacement

L'application utilise une **échelle de 4px** pour les espacements :

- `xxxs` = 4px
- `xxs` = 8px
- `xs` = 12px
- `small` = 16px
- `medium` = 24px ⭐ (standard)
- `large` = 32px
- `xl` = 48px
- `xxl` = 64px
- `xxxl` = 96px

## Migration

Pour migrer le code existant vers les design tokens :

1. **Identifier les valeurs hardcodées** dans les widgets
2. **Remplacer par les tokens appropriés** de `design_tokens.dart`
3. **Vérifier la cohérence visuelle** après migration

### Exemple de migration

**Avant :**
```dart
Container(
  padding: EdgeInsets.all(24),
  margin: EdgeInsets.symmetric(horizontal: 16),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Icon(Icons.add, size: 24),
)
```

**Après :**
```dart
Container(
  padding: EdgeInsets.all(AppSpacing.medium),
  margin: EdgeInsets.symmetric(horizontal: AppSpacing.small),
  decoration: BoxDecoration(
    borderRadius: AppRadius.card,
    boxShadow: AppShadows.medium(Colors.black),
  ),
  child: Icon(Icons.add, size: AppIconSizes.medium),
)
```

## Avantages

✅ **Cohérence visuelle** - Tous les composants utilisent les mêmes valeurs  
✅ **Maintenabilité** - Changement global en un seul endroit  
✅ **Accessibilité** - Respect des standards de spacing et sizing  
✅ **Productivité** - Moins de décisions à prendre pour les développeurs  
✅ **Design system** - Base solide pour l'évolution du design

## Bonnes pratiques

1. **Ne jamais hardcoder** les valeurs d'espacement, de rayon, etc.
2. **Utiliser les tokens prédéfinis** (cardPadding, buttonRadius, etc.) quand disponibles
3. **Créer de nouveaux tokens** si une valeur est utilisée 3+ fois
4. **Documenter les nouveaux tokens** avec des commentaires explicatifs
5. **Tester visuellement** après avoir modifié les tokens

