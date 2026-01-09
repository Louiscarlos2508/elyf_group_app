# Core › Offline

Ce module implémente le mode **offline-first** avec **Drift (SQLite)** et une synchronisation (optionnelle) vers Firebase/Firestore.

## Vue d'ensemble

Principes :

1. **Write local first** : on écrit en base locale immédiatement (UX fluide).
2. **Sync en arrière-plan** : quand en ligne, les opérations peuvent être synchronisées vers Firestore.
3. **Conflits** : résolution basée sur `updated_at` (last write wins) côté SyncManager / handler.

## SyncManager

Le `SyncManager` gère la file d'attente de synchronisation avec Firebase Firestore.

### Fonctionnalités

- ✅ **File d'attente persistante** : Opérations stockées dans Drift (`SyncOperations` table)
- ✅ **Sync automatique** : Périodique (configurable) et au retour en ligne
- ✅ **Retry logic** : Exponential backoff pour les opérations échouées
- ✅ **Support CRUD** : Create, update, delete operations
- ✅ **Statuts** : pending, processing, synced, failed
- ✅ **Tests d'intégration** : Tests complets pour tous les scénarios

### Utilisation

```dart
// Queue une opération de création
await syncManager.queueCreate(
  collectionName: 'users',
  localId: localId,
  data: userData,
  enterpriseId: enterpriseId,
);

// Queue une opération de mise à jour
await syncManager.queueUpdate(
  collectionName: 'users',
  documentId: documentId,
  data: updatedData,
  enterpriseId: enterpriseId,
);

// Queue une opération de suppression
await syncManager.queueDelete(
  collectionName: 'users',
  documentId: documentId,
  enterpriseId: enterpriseId,
);

// Sync manuelle (si nécessaire)
await syncManager.syncPendingOperations();
```

### Configuration

```dart
final syncManager = SyncManager(
  driftService: driftService,
  connectivityService: connectivityService,
  config: const SyncConfig(
    syncIntervalMinutes: 5, // Sync automatique toutes les 5 minutes
    maxRetryAttempts: 3,    // Nombre max de tentatives
  ),
);

await syncManager.initialize();
```

### Architecture

- **SyncManager** : Gère la file d'attente et orchestre la synchronisation
- **SyncOperationDao** : DAO pour la table `SyncOperations` (Drift)
- **FirebaseSyncHandler** : Handler pour synchroniser avec Firebase Firestore
- **RetryHandler** : Gestion des retries avec exponential backoff
- **ConnectivityService** : Détection de la connectivité réseau

### Schéma de la file d'attente

La table `SyncOperations` contient :
- `operationType` : 'create', 'update', 'delete'
- `collectionName` : Nom de la collection Firestore
- `documentId` : ID du document (local ou remote)
- `enterpriseId` : ID de l'entreprise (multi-tenant)
- `payload` : JSON payload pour create/update
- `retryCount` : Nombre de tentatives
- `status` : 'pending', 'processing', 'synced', 'failed'
- `createdAt`, `processedAt`, `localUpdatedAt` : Timestamps

## Stockage local (Drift)

### Service

- `drift_service.dart` : initialise la base SQLite et expose le DAO.

### Schéma

Le stockage actuel est **générique** (JSON) :

- `drift/app_database.dart` : table `OfflineRecords`
- `drift/offline_record_dao.dart` : DAO CRUD

`OfflineRecords` contient :
- `collectionName` (ex: `sales`, `products`)
- `enterpriseId`, `moduleType` (multi-tenant)
- `localId`, `remoteId`
- `dataJson`
- `localUpdatedAt`

## Quick Start

### 1) Initialisation (bootstrap)

```dart
import 'package:elyf_groupe_app/core/offline/offline.dart';

Future<void> bootstrap() async {
  // ...
  await DriftService.instance.initialize();
}
```

### 2) Utiliser les providers

```dart
final isOnline = ref.watch(isOnlineProvider);
final pendingCount = ref.watch(pendingSyncCountProvider);
```

### 3) Exemple d’écriture locale (repository)

Un repository offline utilise `driftService.records` pour persister un JSON multi-tenant :

```dart
await driftService.records.upsert(
  collectionName: 'products',
  localId: localId,
  remoteId: remoteId,
  enterpriseId: enterpriseId,
  moduleType: 'boutique',
  dataJson: jsonEncode(map),
  localUpdatedAt: DateTime.now(),
);
```

## Génération de code (Drift)

Après modification des tables Drift, exécuter :

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Notes

- Le stockage générique (JSON) est volontaire pour permettre une migration rapide.  
  Si une entité nécessite des requêtes avancées, on pourra introduire une table Drift dédiée.


