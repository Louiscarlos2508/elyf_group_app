# ADR-002: Choix de Clean Architecture avec couches

**Statut** : Accepté  
**Date** : 2026-02-XX  
**Auteurs** : Équipe de développement

## Contexte

Le projet nécessite une architecture claire et maintenable pour gérer plusieurs modules fonctionnels (gaz, boutique, eau minérale, immobilier, orange money, administration) avec une séparation claire des responsabilités.

## Décision

Adopter Clean Architecture avec 4 couches :
1. **Presentation** : UI (widgets, screens)
2. **Application** : State management (Riverpod)
3. **Domain** : Logique métier (entités, services, interfaces)
4. **Data** : Implémentations (repositories, sources de données)

## Conséquences

### Positives
- Séparation claire des responsabilités
- Testabilité améliorée (domain indépendant de l'UI)
- Maintenabilité accrue
- Réutilisabilité du code métier
- Indépendance des frameworks (UI et data peuvent changer sans affecter le domain)

### Négatives
- Plus de fichiers et de structure (trade-off accepté)
- Courbe d'apprentissage pour les nouveaux développeurs
- Nécessite une discipline pour respecter les règles de dépendances

### Alternatives Considérées
- **MVC** : Rejeté car trop simple pour un projet multi-modules complexe
- **MVVM** : Rejeté car Riverpod offre déjà une meilleure abstraction
- **Hexagonal Architecture** : Considéré mais Clean Architecture est plus adapté à Flutter

## Références
- [docs/ARCHITECTURE.md](../ARCHITECTURE.md#architecture-par-couches)
- [docs/templates/module_template.md](../templates/module_template.md)

