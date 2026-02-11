# Epic 11: Immobilier Module Stabilization & Integration

## Goal
Transition the Immobilier module from mock data to a full production-ready implementation with Drift persistence, Firestore synchronization, multi-tenancy support, and audit logging.

## Context
The Immobilier module currently exists with a complete UI but uses mock implementations for its repositories. To go live, it must be integrated into the core sync layer and follow the same multi-tenancy patterns as the Eau Minérale and Gaz modules.

## Stories

- [Story 11.1: Database Schema & Entity Alignment](../stories/11.1-immobilier-schema.md)
- [Story 11.2: Real Offline Repositories Implementation](../stories/11.2-immobilier-repositories.md)
- [Story 11.3: Multi-tenancy & Sync Integration](../stories/11.3-immobilier-sync.md)
- [Story 11.4: Real-time UI Binding & Audit Trail](../stories/11.4-immobilier-ui-audit.md)
- [Story 11.5: Printing Integration (Rent Receipts)](../stories/11.5-immobilier-printing.md)

## Success Criteria
- 100% of Immobilier data (Properties, Tenants, Contracts, Payments) is persisted in Drift and synced to Firestore.
- Data is strictly isolated by `enterpriseId`.
- Critical actions (Contract signing, Payments) are logged in the `AuditTrail`.
- Rent receipts can be printed using the `PrintingService`.
