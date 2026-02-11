# Epic 8: Permission Service Unification

## Goal
Unify the various permission services into a single, robust, multi-tenant capable service located in `core/auth`.

## Context
The application had multiple permission services (`PermissionService`, `ImprovedPermissionService`, `RealPermissionService`) and fallback mocks. To ensure security and maintainability, these are unified into a central `FirestorePermissionService` that handles multi-tenant access control consistently.

## Stories

- [Story 8.1: Interface Unification](../stories/8.1-permission-interface.md)
- [Story 8.2: Firestore Permission Service](../stories/8.2-firestore-permission.md)
- [Story 8.3: Module Provider Updates](../stories/8.3-permission-providers.md)
- [Story 8.4: Legacy Cleanup](../stories/8.4-permission-cleanup.md)

## Success Criteria
- A single source of truth for permissions in `core/auth`.
- Native support for `enterpriseId` in all permission checks.
- Zero dependency on the legacy `RealPermissionService`.
- All modules utilize the centralized `unifiedPermissionServiceProvider`.
