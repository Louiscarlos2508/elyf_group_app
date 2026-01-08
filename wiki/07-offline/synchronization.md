# Synchronisation offline

Guide sur le mode **offline-first** et la synchronisation dans ELYF Group App.

## Vue d'ensemble

L'application fonctionne en mode **offline-first** :
- Données stockées localement (**Drift / SQLite**)
- Synchronisation automatique avec Firestore (quand disponible)
- Fonctionnement même sans connexion

## Stockage local (Drift)

Le stockage actuel utilise une table générique `OfflineRecords` qui contient :
- `collectionName` (ex: `products`, `sales`)
- `enterpriseId`, `moduleType` (multi-tenant)
- `localId`, `remoteId`
- `dataJson` (payload JSON)
- `localUpdatedAt`

Les repositories offline utilisent `DriftService.instance.records`.

## Flux de données

### Lecture

1. **Lire localement** (Drift) : instantané, disponible hors-ligne
2. **Si nécessaire** : rafraîchir depuis Firestore (quand en ligne)
3. **Mettre à jour le cache local** (Drift)

Exemple (simplifié) :

```dart
final rows = await driftService.records.listForEnterprise(
  collectionName: 'products',
  enterpriseId: enterpriseId,
  moduleType: 'boutique',
);
final products = rows.map((r) => jsonDecode(r.dataJson)).toList();
```

### Écriture

1. **Écrire localement immédiatement** (Drift) → UX fluide
2. **Enregistrer une opération de sync** (file d’attente) → TODO côté Drift
3. **Synchroniser Firestore en arrière-plan** quand en ligne

## État actuel dans ce repo

- Les **repositories offline** écrivent/lisent depuis Drift (SQLite).
- Le **SyncManager** est présent (stub pour la partie persistance de la file d’attente).
- La synchronisation Firestore peut être complétée en stockant la queue dans Drift.


