# Elyf Group App - Brownfield Architecture Document

## Introduction
This document captures the CURRENT STATE of the Elyf Group App codebase. It serves as a reference for AI agents and developers working on the project.

## Quick Reference
- **Main Entry**: `lib/main.dart`
- **Bootstrap**: `lib/app/bootstrap.dart`
- **Navigation**: `lib/core/navigation/`
- **State Management**: ProviderScope (Riverpod) in `lib/main.dart`
- **Database**: Drift (SQLite) in `lib/core/offline/drift_service.dart`

## High Level Architecture
### Technical Summary
The project is a Flutter application following a feature-first architecture with an offline-first synchronization mechanism between a local SQLite database (Drift) and Firebase Firestore.

### ACTUAL Tech Stack
| Category | Technology | Version | Notes |
| :--- | :--- | :--- | :--- |
| Framework | Flutter | ^3.9.0 | |
| State | Riverpod | ^3.0.3 | |
| Database | Drift | ^2.26.0 | Local SQLite persistence |
| Backend | Firebase | ^3.8.1 | Auth, Firestore, Messaging, Functions |
| Navigation | GoRouter | ^17.0.0 | |

## Project Structure (Actual)
```text
lib/
├── app/               # App-level configuration and bootstrap
├── core/              # Infrastructure: navigation, offline, formatting
│   ├── firebase/      # FCM and Firebase handlers
│   ├── offline/       # SyncManager, Drift, Connectivity
├── features/          # Feature modules (feature-first)
│   ├── administration/
│   ├── eau_minerale/
│   ├── gaz/
│   └── ...
└── shared/            # Shared UI components and utilities
```

## Sync Layer
- **Path definition**: The single source of truth for Firestore collection paths is `lib/core/offline/sync_paths.dart`. It exports a map `collectionPaths` of type `Map<String, String Function(String?)>`: the key is the logical collection name (e.g. `'sales'`, `'enterprise_module_users'`), the value is a function that builds the Firestore path (typically `enterprises/$enterpriseId/...` for per-enterprise data).
- **Bootstrap wiring**: In `lib/app/bootstrap.dart`, the same `collectionPaths` from `sync_paths.dart` is passed to `FirebaseSyncHandler(collectionPaths: collectionPaths)` and to `GlobalModuleRealtimeSyncService(collectionPaths: collectionPaths)`. No collection path is defined elsewhere for sync; all sync services use this single map.
- **Rule for new features**: When adding a new feature module or a new synced collection, the collection name used in the feature's offline repository (e.g. `String get collectionName => 'my_collection';`) must be registered as a key in `lib/core/offline/sync_paths.dart` with the corresponding Firestore path builder. Otherwise sync will not run for that collection.

## Technical Debt and Known Issues
### Critical Technical Debt
1. **Analysis Errors**: Addressed in Story 1.1; `flutter analyze` returns 0 issues.
2. **Global Singletons**: `lib/app/bootstrap.dart` manages multiple global nullable instances (e.g., `globalSyncManager`), which can be difficult to test and maintain.
3. **Manual Sync Routes**: Paths are centralized in `sync_paths.dart` and wired once in bootstrap; new collections must be added to `sync_paths.dart` (see Sync Layer above).

## Implementation Priorities (per BMAD)
1. **Fix Analysis Issues**: Done (Story 1.1).
2. **Modularize Bootstrap**: Refactor global instances into a more robust DI or service locator pattern (already using Riverpod, so could leverage it more).
3. **Enhance Sync Layer**: Better abstraction for feature-specific sync logic; path coverage verified via Story 1.2.
4. **Documentation and unit tests**: Done (Story 1.3). This document kept up to date; unit tests added for critical logic in eau_minerale (CreditService) and gaz (GasValidationService).