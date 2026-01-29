/// Noms de collections centralisés pour éviter les erreurs de typo
/// et garantir la cohérence dans toute l'application.
///
/// Tous les mouvements d'un même type utilisent la même collection,
/// ce qui permet une meilleure organisation et performance.
class CollectionNames {
  CollectionNames._();

  // Collections Eau Minérale
  static const String bobineStocks = 'bobine_stocks';
  static const String bobineStockMovements = 'bobine_stock_movements';
  static const String packagingStocks = 'packaging_stocks';
  static const String packagingStockMovements = 'packaging_stock_movements';
  static const String stockMovements = 'stock_movements';
  static const String stockItems = 'stock_items';
  static const String products = 'products';
  static const String sales = 'sales';
  static const String customers = 'customers';
  static const String machines = 'machines';
  static const String productionSessions = 'production_sessions';
  static const String employees = 'employees';
  static const String salaryPayments = 'salary_payments';
  static const String productionPayments = 'production_payments';
  static const String creditPayments = 'credit_payments';
  static const String dailyWorkers = 'daily_workers';
  static const String expenseRecords = 'expense_records';

  // Collections Gaz
  static const String cylinders = 'cylinders';
  static const String gasSales = 'gas_sales';
  static const String cylinderStocks = 'cylinder_stocks';
  static const String cylinderLeaks = 'cylinder_leaks';
  static const String gazExpenses = 'gaz_expenses';
  static const String tours = 'tours';
  static const String pointOfSale = 'pointOfSale';
  static const String gazSettings = 'gaz_settings';
  static const String financialReports = 'financial_reports';

  // Collections Orange Money
  static const String transactions = 'transactions';
  static const String agents = 'agents';
  static const String commissions = 'commissions';
  static const String liquidityCheckpoints = 'liquidity_checkpoints';
  static const String orangeMoneySettings = 'orange_money_settings';

  // Collections Immobilier
  static const String properties = 'properties';
  static const String tenants = 'tenants';
  static const String contracts = 'contracts';
  static const String payments = 'payments';
  static const String propertyExpenses = 'property_expenses';

  // Collections Boutique
  static const String purchases = 'purchases';
  static const String expenses = 'expenses';
}
