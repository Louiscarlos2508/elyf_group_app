---
description: Brownfield Full-Stack Enhancement
---

# Brownfield Full-Stack Enhancement

Agent workflow for enhancing existing full-stack applications with new features, modernization, or significant changes. Handles existing system analysis and safe integration.

## Steps

1. **Enhancement Classification** (Analyst)
   - Determine enhancement complexity to route to appropriate path.
   - Ask user about scope.

2. **Routing Decision** (PM)
   - Route to `brownfield-create-story` for single stories.
   - Route to `brownfield-create-epic` for small features.
   - Continue with full workflow for major enhancements.

3. **Documentation Check** (Analyst)
   - Check if adequate project documentation exists.

4. **Project Analysis** (Architect)
   - Run `document-project` if documentation is inadequate.

5. **PRD Creation** (PM)
   - Create `prd.md` using `brownfield-prd-tmpl`.

6. **Architecture Decision** (PM/Architect)
   - Determine if architecture document needed.

7. **Architecture Creation** (Architect)
   - Create `architecture.md` if significant changes needed.

8. **PO Validation** (PO)
   - Validate all artifacts for integration safety.

9. **Sharding Documents** (PO)
   - Shard documents for IDE development.

10. **Story Creation** (SM)
    - Create approved stories from sharded documentation.

11. **Implementation** (Dev)
    - Implement approved stories sequentially.

12. **QA Review** (QA)
    - Review implementation and signature quality gate.

13. **Repeat**
    - Continue for all stories.
