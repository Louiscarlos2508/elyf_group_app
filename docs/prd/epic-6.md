# Epic 6: Multi-tenancy & Audit Logging Generalization

## Goal
Generalize the multi-tenancy (`enterpriseId`) and audit logging patterns established in previous epics to the remaining functional modules.

## Context
Modules like `Orange Money`, `Boutique`, and `Immobilier` were partially implemented without full domain-level support for `enterpriseId` or consistent audit trail logging. This epic brings them up to standard to ensure data isolation and traceability across the entire application.

## Stories

- [Story 6.1: Orange Money Multi-tenancy & Audit Logging](../stories/6.1-orange-money-tenancy.md)
- [Story 6.2: Boutique Multi-tenancy & Audit Logging](../stories/6.2-boutique-tenancy.md)
- [Story 6.3: Immobilier Multi-tenancy & Audit Logging](../stories/6.3-immobilier-tenancy.md)

## Success Criteria
- All entities in target modules have an `enterpriseId` field.
- Repositories correctly filter data by `enterpriseId`.
- Controllers log significant business events to the `AuditTrailService`.
- `flutter analyze` reports 0 issues related to these changes.
