# Architecture Decision Records (ADRs)

Ce dossier contient les Architecture Decision Records (ADRs) du projet ELYF Group App.

## Qu'est-ce qu'un ADR ?

Un ADR est un document qui capture une décision architecturale importante, le contexte qui l'a motivée, et les conséquences de cette décision.

## Format d'un ADR

Chaque ADR suit le format suivant :

1. **Titre** : Numéro et nom court de la décision
2. **Statut** : Proposé, Accepté, Rejeté, Déprécié
3. **Contexte** : Pourquoi cette décision était nécessaire
4. **Décision** : La décision prise
5. **Conséquences** : Les impacts positifs et négatifs

## Liste des ADRs

- [ADR-001](ADR-001-features-vs-modules.md) : Utilisation de `features/` au lieu de `modules/`
- [ADR-002](ADR-002-clean-architecture.md) : Choix de Clean Architecture avec couches
- [ADR-003](ADR-003-offline-first-isar.md) : Implémentation offline-first avec Isar
- [ADR-004](ADR-004-riverpod-state-management.md) : Utilisation de Riverpod pour le state management
- [ADR-005](ADR-005-permissions-centralized.md) : Système de permissions centralisé
- [ADR-006](ADR-006-barrel-files.md) : Fichiers barrel pour réduire les imports profonds

## Créer un Nouveau ADR

1. Copier le template : `cp template.md ADR-XXX-description.md`
2. Remplir les sections
3. Mettre à jour cette liste
4. Commiter avec le message : `docs(adr): Add ADR-XXX - Description`

