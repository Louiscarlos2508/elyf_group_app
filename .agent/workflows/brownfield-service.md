---
description: Brownfield Service/API Enhancement
---

# Brownfield Service/API Enhancement

Agent workflow for enhancing existing backend services and APIs with new features, modernization, or performance improvements. Handles existing system analysis and safe integration.

## Steps

1. **Service Analysis** (Architect)
   - Review existing service documentation, codebase, performance metrics, and identify integration dependencies.
   - Run `document-project`.

2. **PRD Creation** (PM)
   - Create `prd.md` using `brownfield-prd-tmpl`.

3. **Architecture Creation** (Architect)
   - Create `architecture.md` with service integration strategy and API evolution planning.

4. **PO Validation** (PO)
   - Validate all documents for service integration safety and API compatibility.

5. **Sharding Documents** (PO)
   - Shard documents for IDE development.

6. **Story Creation** (SM)
   - Create next story from sharded docs.

7. **Implementation** (Dev)
   - Implement approved story sequentially.

8. **QA Review** (QA)
   - Senior dev review with refactoring ability.

9. **Repeat**
   - Continue for all stories.
