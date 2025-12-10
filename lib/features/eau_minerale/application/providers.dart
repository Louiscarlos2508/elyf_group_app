import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_activity_repository.dart';
import '../data/repositories/mock_customer_repository.dart';
import '../data/repositories/mock_finance_repository.dart';
import '../data/repositories/mock_inventory_repository.dart';
import '../data/repositories/mock_product_repository.dart';
import '../domain/services/production_period_service.dart';
import '../data/repositories/mock_production_session_repository.dart';
import '../data/repositories/mock_bobine_repository.dart';
import '../data/repositories/mock_machine_repository.dart';
import '../data/repositories/mock_sales_repository.dart';
import '../data/repositories/mock_report_repository.dart';
import '../data/repositories/mock_salary_repository.dart';
import '../domain/repositories/activity_repository.dart';
import '../domain/repositories/customer_repository.dart';
import '../domain/repositories/finance_repository.dart';
import '../domain/repositories/inventory_repository.dart';
import '../domain/entities/product.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/production_session_repository.dart';
import '../domain/repositories/bobine_repository.dart';
import '../domain/repositories/machine_repository.dart';
import '../domain/adapters/expense_balance_adapter.dart';
import '../domain/entities/expense_report_data.dart';
import '../../../../core/domain/entities/expense_balance_data.dart';
import '../domain/entities/product_sales_summary.dart';
import '../domain/entities/production_report_data.dart';
import '../domain/entities/production_session.dart';
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
import 'controllers/production_session_controller.dart';
import 'controllers/report_controller.dart';
import 'controllers/sales_controller.dart';
import 'controllers/salary_controller.dart';
import 'controllers/stock_controller.dart';
import '../presentation/screens/sections/dashboard_screen.dart';
import '../presentation/screens/sections/production_sessions_screen.dart';
import '../presentation/screens/sections/sales_screen.dart';
import '../presentation/screens/sections/stock_screen.dart';
import '../presentation/screens/sections/clients_screen.dart';
import '../presentation/screens/sections/finances_screen.dart';
import '../presentation/screens/sections/salaries_screen.dart';
import '../presentation/screens/sections/reports_screen.dart';
import '../presentation/screens/sections/profile_screen.dart';
import '../presentation/screens/sections/settings_screen.dart';

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

final productionPeriodServiceProvider = Provider<ProductionPeriodService>(
  (ref) => ProductionPeriodService(),
);

final productionSessionRepositoryProvider =
    Provider<ProductionSessionRepository>(
  (ref) => MockProductionSessionRepository(),
);

final bobineRepositoryProvider = Provider<BobineRepository>(
  (ref) => MockBobineRepository(),
);

final machineRepositoryProvider = Provider<MachineRepository>(
  (ref) => MockMachineRepository(),
);

final productionSessionControllerProvider =
    Provider<ProductionSessionController>(
  (ref) => ProductionSessionController(
    ref.watch(productionSessionRepositoryProvider),
  ),
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
    productionSessionRepository: ref.watch(productionSessionRepositoryProvider),
  ),
);

final reportControllerProvider = Provider<ReportController>(
  (ref) => ReportController(ref.watch(reportRepositoryProvider)),
);

final activityStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(activityControllerProvider).fetchTodaySummary(),
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

/// Provider pour le bilan des dépenses Eau Minérale.
final eauMineraleExpenseBalanceProvider =
    FutureProvider.autoDispose<List<ExpenseBalanceData>>(
  (ref) async {
    final expenses = await ref.read(financesControllerProvider).fetchRecentExpenses();
    final adapter = EauMineraleExpenseBalanceAdapter();
    return adapter.convertToBalanceData(expenses.expenses);
  },
);

final productsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) async => ref.watch(productRepositoryProvider).fetchProducts(),
);

final productionPeriodConfigProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(productionPeriodServiceProvider).getConfig(),
);

final productionSessionsStateProvider = FutureProvider.autoDispose<
    List<ProductionSession>>(
  (ref) async {
    return ref.read(productionSessionControllerProvider).fetchSessions();
  },
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

/// Configuration for a section in the module shell.
class EauMineraleSectionConfig {
  const EauMineraleSectionConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
  });

  final EauMineraleSection id;
  final String label;
  final IconData icon;
  final Widget Function() builder;
}

/// Provider that caches accessible sections for the module shell.
/// Uses autoDispose to allow reloading when navigating away and back.
final accessibleSectionsProvider = FutureProvider.autoDispose<List<EauMineraleSectionConfig>>(
  (ref) async {
    // Ensure minimum loading time to show animation
    final loadingStart = DateTime.now();
    
    final adapter = ref.watch(eauMineralePermissionAdapterProvider);
    final accessible = <EauMineraleSectionConfig>[];
    
    for (final section in _allSections) {
      if (await adapter.canAccessSection(section.id)) {
        accessible.add(section);
      }
    }
    
    // Ensure animation is visible for at least 1.2 seconds
    final elapsed = DateTime.now().difference(loadingStart);
    const minimumDuration = Duration(milliseconds: 1200);
    if (elapsed < minimumDuration) {
      await Future.delayed(minimumDuration - elapsed);
    }
    
    return accessible;
  },
);

final _allSections = [
  EauMineraleSectionConfig(
    id: EauMineraleSection.activity,
    label: 'Tableau',
    icon: Icons.dashboard_outlined,
    builder: () => const DashboardScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.production,
    label: 'Production',
    icon: Icons.factory_outlined,
    builder: () => const ProductionSessionsScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.sales,
    label: 'Ventes',
    icon: Icons.point_of_sale,
    builder: () => const SalesScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.stock,
    label: 'Stock',
    icon: Icons.inventory_2_outlined,
    builder: () => const StockScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.clients,
    label: 'Crédits',
    icon: Icons.credit_card,
    builder: () => const ClientsScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.finances,
    label: 'Dépenses',
    icon: Icons.receipt_long,
    builder: () => const FinancesScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.salaries,
    label: 'Salaires',
    icon: Icons.people,
    builder: () => const SalariesScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.reports,
    label: 'Rapports',
    icon: Icons.description,
    builder: () => const ReportsScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.profile,
    label: 'Profil',
    icon: Icons.person,
    builder: () => const ProfileScreen(),
  ),
  EauMineraleSectionConfig(
    id: EauMineraleSection.settings,
    label: 'Paramètres',
    icon: Icons.settings,
    builder: () => const SettingsScreen(),
  ),
];
