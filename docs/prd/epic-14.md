# Epic 14: Eau Minérale & Gaz Module Stabilization

## Goal
Stabilize the `Eau Minérale` and `Gaz` modules by enforcing strict multi-tenancy, soft-delete capabilities, and standardizing persistence logic across all repositories.

## Context
Following the stabilization of other modules, these two production and distribution modules need to be hardened to ensure data integrity, especially given the offline-first nature of the application and the complexity of inventory and production tracking.

## Stories

- [Story 14.1: Entity Hardening (Audit & Soft-delete)](../stories/14.1-eau-minerale-gaz-entities.md)
- [Story 14.2: Repository Hardening (Persistence & Filters)](../stories/14.2-eau-minerale-gaz-repositories.md)
- [Story 14.3: Controller & Service Refinement](../stories/14.3-eau-minerale-gaz-controllers.md)
- [Story 14.4: Final Verification & Performance Optimization](../stories/14.4-eau-minerale-gaz-verification.md)

## Success Criteria
- 100% of repositories in `Eau Minérale` and `Gaz` modules support soft-delete.
- `enterpriseId` filtering is enforced in all data access operations.
- Entities use standardized `fromMap`/`toMap` serialization for robust data handling.
- Audit fields (`createdAt`, `updatedAt`, `deletedAt`) are consistently populated.
