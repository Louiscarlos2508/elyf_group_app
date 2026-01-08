# Drift Database

Guide sur l'utilisation de **Drift (SQLite)** comme base de données locale dans ELYF Group App.

## Vue d'ensemble

Drift est utilisé pour le stockage local offline-first. Les données sont persistées localement afin de permettre :
- lecture/écriture hors-ligne
- reprise automatique dès que la connectivité revient
- isolation multi-tenant (par `enterpriseId` + `moduleType`)

## Implémentation dans le projet

### Service

- `lib/core/offline/drift_service.dart` : initialise la base SQLite et expose le DAO.

### Schéma (v1)

Le projet utilise un **stockage générique** :

- `lib/core/offline/drift/app_database.dart`
- Table : `OfflineRecords`

Colonnes principales :
- `collectionName` : ex. `products`, `sales`, `expenses`
- `localId` : ID local (ex. `local_...`)
- `remoteId` : ID Firestore (optionnel)
- `enterpriseId` : tenant actif
- `moduleType` : module (ex. `boutique`, `eau_minerale`, `immobilier`, `orange_money`)
- `dataJson` : JSON complet de l'entité (Map sérialisée)
- `localUpdatedAt` : horodatage local (pour tri & conflits)

### DAO (CRUD)

- `lib/core/offline/drift/offline_record_dao.dart`

Opérations disponibles :
- `upsert(...)`
- `findByLocalId(...)` / `findByRemoteId(...)`
- `listForEnterprise(...)`
- `deleteByLocalId(...)` / `deleteByRemoteId(...)`
- `clearAll()` / `clearEnterprise(enterpriseId)`

## Bonnes pratiques

1. **Toujours remplir `enterpriseId` et `moduleType`** (multi-tenant)
2. **Toujours définir `localId`** pour les entités créées offline
3. **Tri côté Dart** quand nécessaire (le stockage JSON est générique)
4. **Évolutif** : si une entité nécessite des requêtes complexes, créer une table dédiée Drift (future amélioration)

## Prochaines étapes

- [Synchronisation](./synchronization.md)
- [Gestion des conflits](./conflict-resolution.md)


