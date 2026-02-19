/// Global collection paths configuration.
///
/// Maps logical collection names to physical Firestore paths.
/// Used by all sync services to ensure consistency.
final collectionPaths = <String, String Function(String?)>{
  // Administration module (collections globales)
  'enterprises': (enterpriseId) => 'enterprises',
  'users': (enterpriseId) => 'users',
  'roles': (enterpriseId) => 'roles',
  'enterprise_module_users': (enterpriseId) => 'enterprise_module_users',

  // Boutique module
  'sales': (enterpriseId) => 'enterprises/${enterpriseId!}/sales',
  'products': (enterpriseId) => 'enterprises/${enterpriseId!}/products',
  'expenses': (enterpriseId) => 'enterprises/${enterpriseId!}/expenses',
  'purchases': (enterpriseId) => 'enterprises/${enterpriseId!}/purchases',
  'suppliers': (enterpriseId) => 'enterprises/${enterpriseId!}/suppliers',
  'supplier_settlements': (enterpriseId) =>
      'enterprises/${enterpriseId!}/supplierSettlements',
  'treasury_operations': (enterpriseId) =>
      'enterprises/${enterpriseId!}/treasuryOperations',
  'closings': (enterpriseId) => 'enterprises/${enterpriseId!}/closings',
  'boutique_settings': (enterpriseId) => 'enterprises/${enterpriseId!}/boutiqueSettings',

  // Eau Minérale module
  'customers': (enterpriseId) => 'enterprises/${enterpriseId!}/customers',
  'machines': (enterpriseId) => 'enterprises/${enterpriseId!}/machines',
  'bobines': (enterpriseId) => 'enterprises/${enterpriseId!}/bobines',
  'production_sessions': (enterpriseId) =>
      'enterprises/${enterpriseId!}/productionSessions',
  'employees': (enterpriseId) => 'enterprises/${enterpriseId!}/employees',
  'salary_payments': (enterpriseId) =>
      'enterprises/${enterpriseId!}/salaryPayments',
  'production_payments': (enterpriseId) =>
      'enterprises/${enterpriseId!}/productionPayments',
  'credit_payments': (enterpriseId) =>
      'enterprises/${enterpriseId!}/creditPayments',
  'daily_workers': (enterpriseId) =>
      'enterprises/${enterpriseId!}/dailyWorkers',
  'bobine_stocks': (enterpriseId) =>
      'enterprises/${enterpriseId!}/bobineStocks',
  'bobine_stock_movements': (enterpriseId) =>
      'enterprises/${enterpriseId!}/bobineStockMovements',
  'expense_records': (enterpriseId) =>
      'enterprises/${enterpriseId!}/expenseRecords',
  'stock_items': (enterpriseId) => 'enterprises/${enterpriseId!}/stockItems',
  'stock_movements': (enterpriseId) =>
      'enterprises/${enterpriseId!}/stockMovements',
  'packaging_stocks': (enterpriseId) =>
      'enterprises/${enterpriseId!}/packagingStocks',
  'packaging_stock_movements': (enterpriseId) =>
      'enterprises/${enterpriseId!}/packagingStockMovements',
  'eau_minerale_treasury_operations': (enterpriseId) =>
      'enterprises/${enterpriseId!}/eauMineraleTreasuryOperations',

  // Orange Money module
  'agents': (enterpriseId) => 'enterprises/${enterpriseId!}/agents',
  'transactions': (enterpriseId) =>
      'enterprises/${enterpriseId!}/transactions',
  'commissions': (enterpriseId) =>
      'enterprises/${enterpriseId!}/commissions',
  'liquidity_checkpoints': (enterpriseId) =>
      'enterprises/${enterpriseId!}/liquidityCheckpoints',
  'orange_money_settings': (enterpriseId) =>
      'enterprises/${enterpriseId!}/orangeMoneySettings',

  // Immobilier module
  'properties': (enterpriseId) => 'enterprises/${enterpriseId!}/properties',
  'tenants': (enterpriseId) => 'enterprises/${enterpriseId!}/tenants',
  'contracts': (enterpriseId) => 'enterprises/${enterpriseId!}/contracts',
  'payments': (enterpriseId) => 'enterprises/${enterpriseId!}/payments',
  'property_expenses': (enterpriseId) =>
      'enterprises/${enterpriseId!}/propertyExpenses',
  'maintenance_tickets': (enterpriseId) =>
      'enterprises/${enterpriseId!}/maintenanceTickets',
  'immobilier_treasury': (enterpriseId) =>
      'enterprises/${enterpriseId!}/immobilierTreasury',
  'immobilier_settings': (enterpriseId) =>
      'enterprises/${enterpriseId!}/immobilierSettings',

  // Gaz module
  'gas_sales': (enterpriseId) => 'enterprises/${enterpriseId!}/gasSales',
  'cylinders': (enterpriseId) => 'enterprises/${enterpriseId!}/cylinders',
  'cylinder_stocks': (enterpriseId) =>
      'enterprises/${enterpriseId!}/cylinderStocks',
  'pointOfSale': (enterpriseId) =>
      'enterprises/${enterpriseId!}/pointsOfSale',
  'tours': (enterpriseId) => 'enterprises/${enterpriseId!}/tours',
  'gaz_expenses': (enterpriseId) =>
      'enterprises/${enterpriseId!}/gazExpenses',
  'cylinder_leaks': (enterpriseId) =>
      'enterprises/${enterpriseId!}/cylinderLeaks',
  'gaz_settings': (enterpriseId) =>
      'enterprises/${enterpriseId!}/gazSettings',
  'inventory_audits': (enterpriseId) =>
      'enterprises/${enterpriseId!}/inventoryAudits',
  'wholesalers': (enterpriseId) =>
      'enterprises/${enterpriseId!}/wholesalers',
  'financial_reports': (enterpriseId) =>
      'enterprises/${enterpriseId!}/financialReports',
  'gaz_sessions': (enterpriseId) =>
      'enterprises/${enterpriseId!}/gazSessions',
  'gaz_treasury_operations': (enterpriseId) =>
      'enterprises/${enterpriseId!}/gazTreasuryOperations',

  // Audit Trail module
  'audit_trail': (enterpriseId) => 'enterprises/${enterpriseId!}/auditTrail',
};
