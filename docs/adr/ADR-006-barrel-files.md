# ADR-006: Fichiers barrel pour réduire les imports profonds

**Statut** : Accepté  
**Date** : 2026-02-XX  
**Auteurs** : Équipe de développement

## Contexte

Le projet avait un problème d'imports très profonds (6+ niveaux de `../`) rendant le code difficile à maintenir et à lire. Plus de 30 fichiers avaient des imports à 6 niveaux.

## Décision

Créer des fichiers barrel (fichiers d'export) à plusieurs niveaux :
1. **Niveau shared/core** : `shared/presentation/widgets/widgets.dart`, `shared/utils/utils.dart`, etc.
2. **Niveau features** : `features/{module}/shared.dart` et `features/{module}/core.dart` pour chaque module

Ces fichiers réexportent les modules communs pour réduire la profondeur des imports.

## Conséquences

### Positives
- Réduction drastique de la profondeur des imports (6 niveaux → 2-3 niveaux)
- Code plus lisible et maintenable
- Structure plus claire
- Réduction de 59% des fichiers avec 5+ niveaux d'imports
- 0 fichier avec 6 niveaux (était 31)

### Négatives
- Plus de fichiers à maintenir (barrel files)
- Risque de circular dependencies si mal gérés
- Nécessite une discipline pour maintenir les exports à jour

### Alternatives Considérées
- **Imports absolus** : Considéré mais nécessite une configuration complexe
- **Restructuration complète** : Rejeté car trop invasif
- **Ne rien faire** : Rejeté car impact négatif sur la maintenabilité

## Références
- [PROJECT_AUDIT_REPORT.md](../../PROJECT_AUDIT_REPORT.md#architecture)
- [docs/ARCHITECTURE.md](../ARCHITECTURE.md#imports)

