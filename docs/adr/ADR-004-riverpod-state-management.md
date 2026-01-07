# ADR-004: Utilisation de Riverpod pour le state management

**Statut** : Accepté  
**Date** : 2026-02-XX  
**Auteurs** : Équipe de développement

## Contexte

Le projet nécessite un système de gestion d'état robuste pour gérer les données asynchrones, la navigation, et l'état des modules multiples.

## Décision

Utiliser **Riverpod** comme solution de state management pour :
- Gestion des providers (repositories, services, controllers)
- Gestion des états asynchrones (AsyncValue)
- Injection de dépendances
- Testabilité

## Conséquences

### Positives
- Type-safe (compile-time safety)
- Testable facilement
- Performance optimisée (rebuilds ciblés)
- Support natif des états asynchrones
- Injection de dépendances intégrée
- Écosystème mature et bien documenté

### Négatives
- Courbe d'apprentissage pour les développeurs non familiers
- Nécessite une compréhension des providers et de leur cycle de vie
- Plus verbeux que certaines alternatives simples

### Alternatives Considérées
- **Provider** : Rejeté car Riverpod est la version améliorée
- **Bloc/Cubit** : Rejeté car plus verbeux et moins adapté à notre cas d'usage
- **GetX** : Rejeté car moins type-safe et moins maintenable
- **setState** : Rejeté car non scalable pour un projet de cette taille

## Références
- [docs/ARCHITECTURE.md](../ARCHITECTURE.md#state-management)
- [Riverpod Documentation](https://riverpod.dev/)

