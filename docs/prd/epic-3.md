# Epic 3: Business Logic Validation & Workflow Robustness

## Description
This epic focuses on strengthening the application's core business logic by implementing automated tests, improving workflow validations in the application layer (controllers/services), and ensuring consistent data integrity across all modules.

## User Stories
- **Story 3.1**: Implement comprehensive unit tests for `ProductService`, `SaleService`, and `ProductionService` in `eau_minerale`.
- **Story 3.2**: Add balance and liquidity checks in `OrangeMoneyController` to prevent over-drawn transactions.
- **Story 3.3**: Implement cylinder stock validation in `GasController` for retail and wholesale workflows.
- **Story 3.4**: Standardize error handling and user feedback for business rule violations across all modules.

## Acceptance Criteria
- 80%+ unit test coverage for domain services in all modules.
- No invalid transactions can be processed (e.g., selling out-of-stock items).
- Consistent audit logs for all critical workflow transitions.
- Improved exception handling in the UI for business-level errors.
