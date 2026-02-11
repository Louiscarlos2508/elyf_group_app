# Epic 12: Boutique Module Stabilization

## Goal
Bring the `Boutique` module to production-ready status by standardizing its entities, repositories, and sync logic to match the current architectural standards (soft-delete, enterprise isolation, audit logging).

## Context
The `Boutique` module currently has basic offline support but lacks consistent soft-delete implementation and comprehensive audit logging. It also needs refinement of its dashboard KPIs to ensure real-time accuracy across enterprises.

## Stories

- [Story 12.1: Entity Alignment (Soft-delete & Audit)](../stories/12.1-boutique-entities.md)
- [Story 12.2: Repository & Sync Hardening](../stories/12.2-boutique-repositories.md)
- [Story 12.3: Dashboard Refinement](../stories/12.3-boutique-dashboard.md)

## Success Criteria
- All Boutique entities (`Product`, `Sale`, `Purchase`, `Expense`) support `isDeleted` and `enterpriseId`.
- Repositories implement `watchDeleted*` and `restore*` methods.
- Every sale, purchase, and expense creation/deletion is recorded in the `AuditTrail`.
- Dashboard metrics match Firestore data 1:1.
