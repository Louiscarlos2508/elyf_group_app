# Gestion des conflits

Ce document décrit la stratégie de résolution de conflits entre la donnée **locale (Drift)** et la donnée **serveur (Firestore)**.

## Principe (last write wins)

Par défaut, la stratégie recommandée est **last write wins** :
- comparer `updated_at` / `updatedAt` (ou champ métier équivalent)
- garder la version la plus récente

## Stratégies possibles

- **serverWins** : le serveur gagne toujours
- **clientWins** : le client gagne toujours
- **lastWriteWins** : le plus récent gagne (défaut)
- **merge** : fusion de champs (à définir par entité)

## Recommandations

1. **Toujours stocker un timestamp** de mise à jour (`updatedAt`) dans les documents Firestore
2. **Tracer `localUpdatedAt`** localement pour le tri et l’audit
3. Pour les conflits complexes, implémenter une stratégie métier (merge contrôlé)

## Références

- `lib/core/offline/sync_manager.dart` (ConflictResolver)
- [Synchronisation](./synchronization.md)
- [Drift Database](./drift-database.md)


