# Epic 7: Printing Infrastructure Stabilization

## Goal
Finalize the integration of the Sunmi V3 Thermal Printer SDK and ensure consistent receipt printing across all modules.

## Context
Printing is a critical requirement for POS operations. The initial implementation was fragmented and relied on mocks. This epic centralizes the printing logic in `SunmiV3Service` and integrates it into the `Gaz`, `Boutique`, and `Eau Minérale` modules.

## Stories

- [Story 7.1: Sunmi V3 Service Implementation](../stories/7.1-sunmi-v3-service.md)
- [Story 7.2: Boutique Printing Integration](../stories/7.2-boutique-printing.md)
- [Story 7.3: Gaz Printing Integration](../stories/7.3-gaz-printing.md)
- [Story 7.4: Eau Minérale Printing Integration](../stories/7.4-eau-minerale-printing.md)

## Success Criteria
- `SunmiV3Service` correctly detects Sunmi hardware and uses the SDK.
- Receipts are correctly formatted and printed on a physical Sunmi V3 device.
- Simulation mode works transparently on non-Sunmi devices (logging to console).
- All three target modules have a functional "Print Receipt" button.
