import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers/cylinder_controller.dart';
import 'controllers/cylinder_leak_controller.dart';
import 'controllers/cylinder_stock_controller.dart';
import 'controllers/expense_controller.dart';
import 'controllers/financial_report_controller.dart';
import 'controllers/gas_controller.dart';
import 'controllers/loading_event_controller.dart';
import 'controllers/site_reconciliation_controller.dart';
import '../data/repositories/mock_cylinder_leak_repository.dart';
import '../data/repositories/mock_cylinder_stock_repository.dart';
import '../data/repositories/mock_expense_repository.dart';
import '../data/repositories/mock_financial_report_repository.dart';
import '../data/repositories/mock_gas_repository.dart';
import '../data/repositories/mock_loading_event_repository.dart';
import '../data/repositories/mock_site_reconciliation_repository.dart';
import '../domain/entities/cylinder.dart';
import '../domain/entities/cylinder_leak.dart';
import '../domain/entities/cylinder_stock.dart';
import '../domain/entities/expense.dart';
import '../domain/entities/financial_report.dart';
import '../domain/entities/gas_sale.dart';
import '../domain/entities/loading_event.dart';
import '../domain/entities/report_data.dart';
import '../domain/entities/site_reconciliation.dart';
import '../domain/repositories/cylinder_leak_repository.dart';
import '../domain/repositories/cylinder_stock_repository.dart';
import '../domain/repositories/expense_repository.dart';
import '../domain/repositories/financial_report_repository.dart';
import '../domain/repositories/gas_repository.dart';
import '../domain/repositories/loading_event_repository.dart';
import '../domain/repositories/site_reconciliation_repository.dart';
import '../domain/services/financial_calculation_service.dart';
import '../domain/services/loading_event_service.dart';
import '../domain/services/stock_service.dart';

// Repositories
final gasRepositoryProvider = Provider<GasRepository>((ref) {
  return MockGasRepository();
});

final gazExpenseRepositoryProvider = Provider<GazExpenseRepository>((ref) {
  return MockGazExpenseRepository();
});

final cylinderStockRepositoryProvider =
    Provider<CylinderStockRepository>((ref) {
  return MockCylinderStockRepository();
});

final loadingEventRepositoryProvider =
    Provider<LoadingEventRepository>((ref) {
  return MockLoadingEventRepository();
});

final cylinderLeakRepositoryProvider =
    Provider<CylinderLeakRepository>((ref) {
  return MockCylinderLeakRepository();
});

final siteReconciliationRepositoryProvider =
    Provider<SiteReconciliationRepository>((ref) {
  return MockSiteReconciliationRepository();
});

final financialReportRepositoryProvider =
    Provider<FinancialReportRepository>((ref) {
  return MockFinancialReportRepository();
});

// Services
final loadingEventServiceProvider = Provider<LoadingEventService>((ref) {
  final loadingEventRepo = ref.watch(loadingEventRepositoryProvider);
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  return LoadingEventService(
    loadingEventRepository: loadingEventRepo,
    stockRepository: stockRepo,
  );
});

final financialCalculationServiceProvider =
    Provider<FinancialCalculationService>((ref) {
  final expenseRepo = ref.watch(gazExpenseRepositoryProvider);
  final loadingEventRepo = ref.watch(loadingEventRepositoryProvider);
  return FinancialCalculationService(
    expenseRepository: expenseRepo,
    loadingEventRepository: loadingEventRepo,
  );
});

final stockServiceProvider = Provider<StockService>((ref) {
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  return StockService(stockRepository: stockRepo);
});

// Controllers
final cylinderControllerProvider = Provider<CylinderController>((ref) {
  final repo = ref.watch(gasRepositoryProvider);
  return CylinderController(repo);
});

final gasControllerProvider = Provider<GasController>((ref) {
  final repo = ref.watch(gasRepositoryProvider);
  return GasController(repo);
});

final expenseControllerProvider =
    Provider<GazExpenseController>((ref) {
  final repo = ref.watch(gazExpenseRepositoryProvider);
  return GazExpenseController(repo);
});

final cylinderStockControllerProvider =
    Provider<CylinderStockController>((ref) {
  final repo = ref.watch(cylinderStockRepositoryProvider);
  final service = ref.watch(stockServiceProvider);
  return CylinderStockController(repo, service);
});

final cylinderLeakControllerProvider = Provider<CylinderLeakController>((ref) {
  final leakRepo = ref.watch(cylinderLeakRepositoryProvider);
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  return CylinderLeakController(leakRepo, stockRepo);
});

final loadingEventControllerProvider = Provider<LoadingEventController>((ref) {
  final repo = ref.watch(loadingEventRepositoryProvider);
  final service = ref.watch(loadingEventServiceProvider);
  return LoadingEventController(repo, service);
});

final siteReconciliationControllerProvider =
    Provider<SiteReconciliationController>((ref) {
  final repo = ref.watch(siteReconciliationRepositoryProvider);
  return SiteReconciliationController(repo);
});

final financialReportControllerProvider =
    Provider<FinancialReportController>((ref) {
  final repo = ref.watch(financialReportRepositoryProvider);
  final service = ref.watch(financialCalculationServiceProvider);
  return FinancialReportController(repo, service);
});

// Cylinders
final cylindersProvider = FutureProvider<List<Cylinder>>((ref) async {
  final repo = ref.watch(gasRepositoryProvider);
  return repo.getCylinders();
});

// Sales
final gasSalesProvider = FutureProvider<List<GasSale>>((ref) async {
  final repo = ref.watch(gasRepositoryProvider);
  return repo.getSales();
});

// Expenses
final gazExpensesProvider = FutureProvider<List<GazExpense>>((ref) async {
  final repo = ref.watch(gazExpenseRepositoryProvider);
  return repo.getExpenses();
});

// KPIs
final gazTotalSalesProvider = FutureProvider<double>((ref) async {
  final sales = await ref.watch(gasSalesProvider.future);
  return sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
});

final gazTotalExpensesProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(gazExpenseRepositoryProvider);
  return repo.getTotalExpenses();
});

final gazProfitProvider = FutureProvider<double>((ref) async {
  final totalSales = await ref.watch(gazTotalSalesProvider.future);
  final totalExpenses = await ref.watch(gazTotalExpensesProvider.future);
  return totalSales - totalExpenses;
});

// Report Data Provider
final gazReportDataProvider = FutureProvider.family.autoDispose<
    GazReportData,
    ({
      GazReportPeriod period,
      DateTime? startDate,
      DateTime? endDate,
    })>((ref, params) async {
  final salesAsync = ref.watch(gasSalesProvider);
  final expensesAsync = ref.watch(gazExpensesProvider);

  final sales = await salesAsync.when(
    data: (data) async => data,
    loading: () async => <GasSale>[],
    error: (_, __) async => <GasSale>[],
  );

  final expenses = await expensesAsync.when(
    data: (data) async => data,
    loading: () async => <GazExpense>[],
    error: (_, __) async => <GazExpense>[],
  );

  // Calculate date range
  DateTime rangeStart;
  DateTime rangeEnd;

  final now = DateTime.now();
  switch (params.period) {
    case GazReportPeriod.today:
      rangeStart = DateTime(now.year, now.month, now.day);
      rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;
    case GazReportPeriod.week:
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      rangeStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
      rangeEnd = now;
      break;
    case GazReportPeriod.month:
      rangeStart = DateTime(now.year, now.month, 1);
      rangeEnd = now;
      break;
    case GazReportPeriod.year:
      rangeStart = DateTime(now.year, 1, 1);
      rangeEnd = now;
      break;
    case GazReportPeriod.custom:
      rangeStart = params.startDate ?? DateTime(now.year, now.month, 1);
      rangeEnd = params.endDate ?? now;
      break;
  }

  // Filter sales and expenses by date range
  final filteredSales = sales.where((s) {
    return s.saleDate.isAfter(rangeStart.subtract(const Duration(days: 1))) &&
        s.saleDate.isBefore(rangeEnd.add(const Duration(days: 1)));
  }).toList();

  final filteredExpenses = expenses.where((e) {
    return e.date.isAfter(rangeStart.subtract(const Duration(days: 1))) &&
        e.date.isBefore(rangeEnd.add(const Duration(days: 1)));
  }).toList();

  // Calculate totals
  final salesRevenue =
      filteredSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  final expensesAmount =
      filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);
  final profit = salesRevenue - expensesAmount;

  // Count by type
  final retailCount =
      filteredSales.where((s) => s.saleType == SaleType.retail).length;
  final wholesaleCount = filteredSales.length - retailCount;

  return GazReportData(
    period: params.period,
    salesRevenue: salesRevenue,
    expensesAmount: expensesAmount,
    profit: profit,
    salesCount: filteredSales.length,
    expensesCount: filteredExpenses.length,
    retailSalesCount: retailCount,
    wholesaleSalesCount: wholesaleCount,
  );
});

// Cylinder Stocks
final cylinderStocksProvider = FutureProvider.family<List<CylinderStock>, ({
  String enterpriseId,
  CylinderStatus? status,
  String? siteId,
})>((ref, params) async {
  final repo = ref.watch(cylinderStockRepositoryProvider);
  if (params.status != null) {
    return repo.getStocksByStatus(
      params.enterpriseId,
      params.status!,
      siteId: params.siteId,
    );
  }
  // Si pas de statut spécifié, retourner tous les stocks
  final allStocks = <CylinderStock>[];
  for (final status in CylinderStatus.values) {
    final stocks = await repo.getStocksByStatus(
      params.enterpriseId,
      status,
      siteId: params.siteId,
    );
    allStocks.addAll(stocks);
  }
  return allStocks;
});

// Loading Events
final loadingEventsProvider = FutureProvider.family<List<LoadingEvent>, ({
  String enterpriseId,
  LoadingEventStatus? status,
})>((ref, params) async {
  final repo = ref.watch(loadingEventRepositoryProvider);
  return repo.getLoadingEvents(
    params.enterpriseId,
    status: params.status,
  );
});

// Cylinder Leaks
final cylinderLeaksProvider = FutureProvider.family<List<CylinderLeak>, ({
  String enterpriseId,
  LeakStatus? status,
})>((ref, params) async {
  final repo = ref.watch(cylinderLeakRepositoryProvider);
  return repo.getLeaks(params.enterpriseId, status: params.status);
});

// Site Reconciliations
final siteReconciliationsProvider = FutureProvider.family<
    List<SiteReconciliation>,
    ({
  String enterpriseId,
  String siteId,
})>((ref, params) async {
  final repo = ref.watch(siteReconciliationRepositoryProvider);
  return repo.getReconciliationsBySite(
    params.enterpriseId,
    params.siteId,
  );
});

// Financial Reports
final financialReportsProvider = FutureProvider.family<List<FinancialReport>, ({
  String enterpriseId,
  ReportPeriod? period,
  ReportStatus? status,
})>((ref, params) async {
  final repo = ref.watch(financialReportRepositoryProvider);
  return repo.getReports(
    params.enterpriseId,
    period: params.period,
    status: params.status,
  );
});
