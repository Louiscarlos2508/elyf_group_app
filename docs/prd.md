# PRD - Project Stabilization & Quality Improvement

## Goal Description
Improve the `elyf_group_app` by resolving 415 analysis issues, stabilizing the synchronization layer, and addressing technical debt identified in the brownfield architecture.

## Target Audience
- Developers and Maintainers
- AI Agents working on the project

## Current State Analysis
- **Lints/Warnings**: 415 issues reported by `flutter analyze`.
- **Architecture**: Feature-first with offline-first sync (Drift + Firebase).
- **Risks**: Potential regressions in synchronization and data integrity during large-scale refactoing.

## Requirements

### R1: Analysis Cleanup (P0)
- Resolve all 415 issues reported by `flutter analyze`.
- Prioritize warnings over infos.
- Standardize on `flutter_lints` and project-specific rules in `analysis_options.yaml`.

### R2: Sync Layer Stabilization (P1)
- Verify that `globalSyncManager` and `FirestoreSyncService` correctly handle all collection paths defined in `bootstrap.dart`.
- Ensure offline operations are robust and sync resumes correctly after network changes.

### R3: Documentation Update (P2)
- Update `docs/brownfield-architecture.md` as improvements are made.
- Create unit tests for critical business logic in `features/eau_minerale` and `features/gaz`.

## Success Metrics
- `flutter analyze` returns 0 issues.
- All existing tests pass.
- Application launches and syncs data correctly on current platform.
