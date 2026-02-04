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

## Technical Debt and Known Issues
### Critical Technical Debt
1. **Analysis Errors**: 415 issues found by `flutter analyze` including warnings and lints.
2. **Global Singletons**: `lib/app/bootstrap.dart` manages multiple global nullable instances (e.g., `globalSyncManager`), which can be difficult to test and maintain.
3. **Manual Sync Routes**: Mapping Firestore collection paths manually in `bootstrap.dart` is error-prone and hard to scale.

## Implementation Priorities (per BMAD)
1. **Fix Analysis Issues**: Resolve the 415 lint warnings to stabilize the codebase.
2. **Modularize Bootstrap**: Refactor global instances into a more robust DI or service locator pattern (already using Riverpod, so could leverage it more).
3. **Enhance Sync Layer**: Better abstraction for feature-specific sync logic.
