# ADR-001: Utilisation de `features/` au lieu de `modules/`

**Statut** : Accepté  
**Date** : 2026-02-XX  
**Auteurs** : Équipe de développement

## Contexte

Le projet devait initialement utiliser `lib/modules/` pour organiser le code par module fonctionnel. Cependant, lors de l'implémentation, `lib/features/` a été utilisé à la place.

## Décision

Utiliser `lib/features/` au lieu de `lib/modules/` pour organiser les modules fonctionnels.

**Justification** :
- `features/` est une meilleure pratique moderne dans l'écosystème Flutter/Dart
- Aligné avec les recommandations de Clean Architecture et Feature-First
- Plus cohérent avec les conventions de packages Dart modernes
- Meilleure séparation des préoccupations (chaque feature est autonome)

## Conséquences

### Positives
- Structure plus claire et intuitive pour les développeurs
- Chaque feature est isolée et peut être développée/testée indépendamment
- Facilite la modularisation et la réutilisation
- Compatible avec les outils de génération de code Flutter
- Aligné avec les pratiques de l'industrie

### Négatives
- Écart avec la spécification originale (documenté dans `lib/features/README.md`)
- Possible confusion initiale pour les nouveaux développeurs

### Alternatives Considérées
- **`lib/modules/`** : Rejeté car moins moderne et moins aligné avec les pratiques Flutter
- **`lib/app/`** : Rejeté car trop générique et ne reflète pas la structure feature-first

## Références
- [lib/features/README.md](../../lib/features/README.md)
- [docs/ARCHITECTURE.md](../ARCHITECTURE.md)

