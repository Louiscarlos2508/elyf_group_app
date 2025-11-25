import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_activity_repository.dart';
import '../data/repositories/mock_customer_repository.dart';
import '../data/repositories/mock_finance_repository.dart';
import '../data/repositories/mock_inventory_repository.dart';
import '../data/repositories/mock_product_repository.dart';
import '../data/repositories/mock_production_repository.dart';
import '../data/repositories/mock_sales_repository.dart';
import '../data/repositories/mock_report_repository.dart';
import '../data/repositories/mock_salary_repository.dart';
import '../domain/repositories/activity_repository.dart';
import '../domain/repositories/customer_repository.dart';
import '../domain/repositories/finance_repository.dart';
import '../domain/repositories/inventory_repository.dart';
import '../domain/entities/product.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/production_repository.dart';
import '../domain/entities/expense_report_data.dart';
import '../domain/entities/product_sales_summary.dart';
import '../domain/entities/production_report_data.dart';
import '../domain/entities/report_data.dart';
import '../domain/entities/report_period.dart';
import '../domain/entities/salary_report_data.dart';
import '../domain/entities/sale.dart';
import '../domain/repositories/report_repository.dart';
import '../domain/repositories/sales_repository.dart';
import '../domain/repositories/salary_repository.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart'
    show permissionServiceProvider;
import '../../../core/permissions/services/permission_service.dart';
import '../../../core/permissions/services/permission_registry.dart';
import '../domain/permissions/eau_minerale_permissions.dart';
import '../application/adapters/eau_minerale_permission_adapter.dart';
import 'controllers/activity_controller.dart';
import 'controllers/clients_controller.dart';
import 'controllers/finances_controller.dart';
import 'controllers/production_controller.dart';
import 'controllers/report_controller.dart';
import 'controllers/sales_controller.dart';
import 'controllers/salary_controller.dart';
import 'controllers/stock_controller.dart';

final productionRepositoryProvider = Provider<ProductionRepository>(
  (ref) => MockProductionRepository(),
);

final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => MockSalesRepository(),
);

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => MockInventoryRepository(),
);

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => MockCustomerRepository(),
);

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => MockFinanceRepository(),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => MockProductRepository(),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => MockActivityRepository(),
);

final activityControllerProvider = Provider<ActivityController>(
  (ref) => ActivityController(ref.watch(activityRepositoryProvider)),
);

final productionControllerProvider = Provider<ProductionController>(
  (ref) => ProductionController(ref.watch(productionRepositoryProvider)),
);

final salesControllerProvider = Provider<SalesController>(
  (ref) => SalesController(ref.watch(salesRepositoryProvider)),
);

final stockControllerProvider = Provider<StockController>(
  (ref) => StockController(ref.watch(inventoryRepositoryProvider)),
);

final clientsControllerProvider = Provider<ClientsController>(
  (ref) => ClientsController(ref.watch(customerRepositoryProvider)),
);

final financesControllerProvider = Provider<FinancesController>(
  (ref) => FinancesController(ref.watch(financeRepositoryProvider)),
);

final salaryRepositoryProvider = Provider<SalaryRepository>(
  (ref) => MockSalaryRepository(),
);

final salaryControllerProvider = Provider<SalaryController>(
  (ref) => SalaryController(ref.watch(salaryRepositoryProvider)),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => MockReportRepository(
    salesRepository: ref.watch(salesRepositoryProvider),
    financeRepository: ref.watch(financeRepositoryProvider),
    salaryRepository: ref.watch(salaryRepositoryProvider),
    productionRepository: ref.watch(productionRepositoryProvider),
  ),
);

final reportControllerProvider = Provider<ReportController>(
  (ref) => ReportController(ref.watch(reportRepositoryProvider)),
);

final activityStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(activityControllerProvider).fetchTodaySummary(),
);

final productionStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(productionControllerProvider).fetchAllProductions(),
);

final salesStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(salesControllerProvider).fetchRecentSales(),
);

final stockStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(stockControllerProvider).fetchSnapshot(),
);

final clientsStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(clientsControllerProvider).fetchCustomers(),
);

final financesStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(financesControllerProvider).fetchRecentExpenses(),
);

final productsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) async => ref.watch(productRepositoryProvider).fetchProducts(),
);

final productionPeriodConfigProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(productionControllerProvider).getPeriodConfig(),
);

final salaryStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(salaryControllerProvider).fetchSalaries(),
);

final reportDataProvider = FutureProvider.autoDispose.family<ReportData, ReportPeriod>(
  (ref, period) async => ref.watch(reportControllerProvider).fetchReportData(period),
);

final reportSalesProvider = FutureProvider.autoDispose.family<List<Sale>, ReportPeriod>(
  (ref, period) async => ref.watch(reportControllerProvider).fetchSalesForPeriod(period),
);

final reportProductSummaryProvider = FutureProvider.autoDispose.family<List<ProductSalesSummary>, ReportPeriod>(
  (ref, period) async => ref.watch(reportControllerProvider).fetchProductSalesSummary(period),
);

final reportProductionProvider = FutureProvider.autoDispose.family<ProductionReportData, ReportPeriod>(
  (ref, period) async => ref.watch(reportControllerProvider).fetchProductionReport(period),
);

final reportExpenseProvider = FutureProvider.autoDispose.family<ExpenseReportData, ReportPeriod>(
  (ref, period) async => ref.watch(reportControllerProvider).fetchExpenseReport(period),
);

final reportSalaryProvider = FutureProvider.autoDispose.family<SalaryReportData, ReportPeriod>(
  (ref, period) async => ref.watch(reportControllerProvider).fetchSalaryReport(period),
);

/// Initialize permissions when module loads
void _initializeEauMineralePermissions() {
  EauMineralePermissionAdapter.initialize();
}

/// Provider for centralized permission service.
/// Uses the shared permission service from administration module.
final centralizedPermissionServiceProvider = Provider<PermissionService>(
  (ref) {
    // Initialize permissions on first access
    _initializeEauMineralePermissions();
    return ref.watch(permissionServiceProvider);
  },
);

/// Provider for current user ID.
/// In development, uses default user with full access for the module.
/// TODO: Replace with actual auth system when available
final currentUserIdProvider = Provider<String>(
  (ref) => 'default_user_eau_minerale', // Default user with full access
);

/// Provider for eau_minerale permission adapter.
final eauMineralePermissionAdapterProvider = Provider<EauMineralePermissionAdapter>(
  (ref) => EauMineralePermissionAdapter(
    permissionService: ref.watch(centralizedPermissionServiceProvider),
    userId: ref.watch(currentUserIdProvider),
  ),
);

/// Enum used for bottom navigation in the module shell.
enum EauMineraleSection {
  activity,
  production,
  sales,
  stock,
  clients,
  finances,
  salaries,
  reports,
  profile,
  settings,
}
