# ADR-003: Implémentation offline-first avec Drift

**Statut** : Accepté  
**Date** : 2026-01-07  
**Auteurs** : Équipe de développement

## Contexte

L'application doit fonctionner en mode offline pour garantir la disponibilité même sans connexion internet. Une stratégie offline-first est nécessaire avec synchronisation automatique avec Firebase/Firestore.

Le projet utilisait (ou documentait) une solution précédente pour le stockage local, mais nous migrons vers **Drift (SQLite)** pour :
- Support durable sur les versions récentes de Dart/Flutter
- Accès SQLite robuste et portable
- Requêtes typées, testables, et migrations via Drift

## Décision

Implémenter l’architecture offline-first avec :
- **Drift (SQLite)** : base de données locale
- **`DriftService`** : initialisation DB + accès aux DAO
- **Stockage générique `OfflineRecords`** : une table SQLite qui stocke chaque entité en **JSON** (`dataJson`) + colonnes indexables (`enterpriseId`, `moduleType`, `collectionName`, `localId`, `remoteId`, `localUpdatedAt`)
- **`OfflineRecordDao`** : opérations CRUD et listing par entreprise/module
- **`OfflineRepository<T>`** : base des repositories offline-first (write local first)
- **`SyncManager`** + `FirebaseSyncHandler` : synchronisation (file d’attente & retry) — à compléter côté Drift si nécessaire

## Conséquences

### Positives
- Application utilisable sans internet (lecture/écriture locales)
- Stockage local stable via SQLite
- Multi-tenant respecté via `enterpriseId` + `moduleType`
- Migration progressive possible (tout module/entity peut basculer vers Drift sans schema complexe)

### Négatives
- Stockage JSON générique : certaines requêtes avancées devront être filtrées côté Dart (ou évoluer vers des tables typées)
- Nécessite `build_runner`/`drift_dev` pour la génération
- Une migration de données vers Drift pourra être nécessaire si une solution précédente avait été déployée en production

## Alternatives considérées
- **SQLite raw** : plus bas niveau, plus de boilerplate, moins typé
- **ObjectBox** : non utilisé - décision prise pour Drift (SQLite) exclusivement pour l'écosystème et la stabilité
- **Hive** : moins adapté aux besoins de requêtes/migrations et à la cohérence multi-tenant

**Note importante** : Drift est la **seule solution** utilisée pour le stockage offline dans ce projet. Aucune migration vers ObjectBox n'est prévue.

## Références

- [docs/ARCHITECTURE.md](../ARCHITECTURE.md#offline-first-architecture)
- `lib/core/offline/drift_service.dart`
- `lib/core/offline/drift/app_database.dart`
- `lib/core/offline/drift/offline_record_dao.dart`


