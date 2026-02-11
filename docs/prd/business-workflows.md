# Business Workflows & Logic Specifications

This document outlines the core business rules and workflows for each module in the `elyf_group_app`.

## 1. Eau Minérale (Production & Sales)

### Workflow: Production
1.  **Preparation**: Selection of raw materials (if tracked).
2.  **Session Start**: Automatic calculation of period (Morning/Afternoon/Night).
3.  **Recording**: Inputting quantity of finished goods.
4.  **Impact**: 
    -   Increase finished goods stock.
    -   Decrease raw materials (packaging, bobines) if specified.
    -   Log production event for employee commissions.

### Workflow: Sales & Credits
1.  **Checkout**: Direct sale (validated) or Credit sale.
2.  **Validation**: Check stock availability before completing.
3.  **Credit Management**: If partial payment, record remaining balance on customer profile.
4.  **Encashment**: Record payments for existing credits, updating `rest_to_pay`.

---

## 2. Gaz (Cylinder Distribution)

### Workflow: Cylinder Lifecycle
1.  **Inventory**: Tracking by type (6kg, 12kg, etc.) and weight.
2.  **Retail Sales**: Individual sale at point of sale.
3.  **Wholesale/Tours**: Planned delivery tours with multiple drop-offs.
4.  **Leaks**: Reporting defective cylinders, adjusting stock without a sale record.

### Workflow: Supply Tours
1.  **Initialization**: Loading vehicle with stock.
2.  **Field Ops**: Recording sales/deposits at different stops.
3.  **Close Out**: Reconciling remaining stock vs. sales vs. initial load.

---

## 3. Boutique (POS & Inventory)

### Workflow: Point of Sale (POS)
1.  **Basket Creation**: Scanning or selecting products.
2.  **Transaction**: Applying discounts and choosing payment methods.
3.  **Inventory Impact**: Immediate decrement of quantities.

### Workflow: Purchases (Stock In)
1.  **Order Recording**: Recording stock entry from suppliers.
2.  **Costing**: Updating weighted average cost or last purchase price.
3.  **Impact**: Increment quantities and update supplier balance.

---

## 4. Orange Money (Transaction Management)

### Workflow: Cash-In/Cash-Out
1.  **Operation**: Recording the type of transaction.
2.  **Verification**: Ensuring agent liquidity is sufficient for cash-out.
3.  **Commissions**: Automatic calculation based on tiered rates or flat fees.

### Workflow: Liquidity Reconciliation
1.  **Maturin Check**: Initial balance verification.
2.  **Evening Check**: Final balance verification vs. daily transaction volume.

---

## 5. Immobilier (Property Management)

### Workflow: Rental Lifecycle
1.  **Booking**: Identifying property and tenant.
2.  **Contract**: Setting rent amount, deposit, and term.
3.  **Rent Payment**: Periodic recording of payments; alerts for late payments.

---

## 6. Administration (Global Control)

### Workflow: Multi-Tenant Provisioning
1.  **Enterprise Creation**: Setup of enterprise identity.
2.  **Module Activation**: Enabling specific features (Gaz, Boutique, etc.).
3.  **User Access**: Assigning `UserId` to `EnterpriseId` with a specific `RoleId` and `ModuleId`.
4.  **Audit**: Recording every administrative change for traceability.
