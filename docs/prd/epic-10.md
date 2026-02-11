# Epic 10: Quality & DX Improvements

## Goal
Improve technical debt, developer experience, and CI/CD stability.

## Context
As the project grows, maintaining a high speed of development requires stable tools and clear patterns. This epic addresses environment-specific dependencies (like `libsqlite3`) and standardizes logging for better observability.

## Stories

- [Story 10.1: CI Dependency Resolution](../stories/10.1-ci-dependencies.md)
- [Story 10.2: Standardized Observability](../stories/10.2-logging-standardization.md)

## Success Criteria
- CI builds pass consistently without manual `libsqlite3` installation.
- `AppLogger` is used across all modules for consistent log levels and metadata.
- Improved error feedback in development.
