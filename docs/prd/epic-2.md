# Epic 2: Bootstrap & State Management Modularization

## Description
Refactor the application's initialization logic and global service instances to use a more robust dependency injection pattern, leveraging the existing Riverpod state management system. This reduces reliance on global mutable state and improves testability.

## User Stories
- **Story 2.1**: Refactor global instances in `bootstrap.dart` to Riverpod providers.
- **Story 2.2**: Migrate `AuthService` and `TenantProvider` to use modular dependencies.
- **Story 2.3**: Standardize feature-specific sync logic using the new DI pattern.

## Acceptance Criteria
- No more global nullable instances in `lib/app/bootstrap.dart`.
- Core services (Sync, Connectivity, Messaging) are accessible via Riverpod.
- Unit tests can easily mock these services.
