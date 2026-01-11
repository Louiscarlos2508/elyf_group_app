import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'providers/permission_providers.dart';
export 'providers/section_providers.dart';
import 'providers/permission_providers.dart' show currentUserIdProvider;
import '../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;

import '../../../core/offline/drift_service.dart';
import '../../../core/offline/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../data/repositories/expense_offline_repository.dart';
import '../data/repositories/purchase_offline_repository.dart';
import '../data/repositories/mock_report_repository.dart';
import '../data/repositories/stock_offline_repository.dart';
import '../data/repositories/product_offline_repository.dart';
import '../data/repositories/sale_offline_repository.dart';
import '../domain/adapters/expense_balance_adapter.dart';
import '../domain/entities/report_data.dart';
import '../domain/repositories/expense_repository.dart';
import '../../../../core/domain/entities/expense_balance_data.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/purchase_repository.dart';
import '../domain/repositories/report_repository.dart';
import '../domain/repositories/sale_repository.dart';
import '../domain/repositories/stock_repository.dart';
import '../domain/services/calculation/cart_calculation_service.dart';
import '../domain/services/cart_service.dart';
import '../domain/services/dashboard_calculation_service.dart';
import '../domain/services/product_calculation_service.dart';
import '../domain/services/product_filter_service.dart';
import '../domain/services/report_calculation_service.dart';
import '../domain/services/validation/product_validation_service.dart';
import 'controllers/store_controller.dart';

/// Provider for BoutiqueDashboardCalculationService.
final boutiqueDashboardCalculationServiceProvider =
    Provider<BoutiqueDashboardCalculationService>(
  (ref) => BoutiqueDashboardCalculationService(),
);

/// Provider for ProductCalculationService.
final productCalculationServiceProvider = Provider<ProductCalculationService>(
  (ref) => ProductCalculationService(),
);

/// Provider for BoutiqueReportCalculationService.
final boutiqueReportCalculationServiceProvider =
    Provider<BoutiqueReportCalculationService>(
  (ref) => BoutiqueReportCalculationService(),
);

/// Provider for CartCalculationService.
final cartCalculationServiceProvider = Provider<CartCalculationService>(
  (ref) => CartCalculationService(),
);

/// Provider for ProductValidationService.
final productValidationServiceProvider = Provider<ProductValidationService>(
  (ref) => ProductValidationService(),
);

/// Provider for CartService.
final cartServiceProvider = Provider<CartService>(
  (ref) => CartService(),
);

/// Provider for ProductFilterService.
final productFilterServiceProvider = Provider<ProductFilterService>(
  (ref) => ProductFilterService(),
);

/// Provider for ProductOfflineRepository.
/// 
/// Requires active enterprise to be set.
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return ProductOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
      moduleType: 'boutique',
    );
  },
);

/// Provider for SaleOfflineRepository.
/// 
/// Requires active enterprise to be set.
final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return SaleOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
      moduleType: 'boutique',
    );
  },
);

final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => StockOfflineRepository(
    productRepository: ref.watch(productRepositoryProvider),
  ),
);

final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return PurchaseOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
      moduleType: 'boutique',
    );
  },
);

/// Provider for ExpenseOfflineRepository.
/// 
/// Requires active enterprise to be set.
final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return ExpenseOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
      moduleType: 'boutique',
    );
  },
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => MockReportRepository(
    ref.watch(saleRepositoryProvider),
    ref.watch(purchaseRepositoryProvider),
    ref.watch(expenseRepositoryProvider),
    ref.watch(productRepositoryProvider),
  ),
);

final storeControllerProvider = Provider<StoreController>(
  (ref) => StoreController(
    ref.watch(productRepositoryProvider),
    ref.watch(saleRepositoryProvider),
    ref.watch(stockRepositoryProvider),
    ref.watch(purchaseRepositoryProvider),
    ref.watch(expenseRepositoryProvider),
    ref.watch(reportRepositoryProvider),
    ref.watch(currentUserIdProvider),
  ),
);

final productsProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(storeControllerProvider).fetchProducts(),
);

final recentSalesProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(storeControllerProvider).fetchRecentSales(),
);

final lowStockProductsProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(storeControllerProvider).getLowStockProducts(),
);

final purchasesProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(storeControllerProvider).fetchPurchases(),
);

final expensesProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(storeControllerProvider).fetchExpenses(),
);

/// Provider pour le bilan des dépenses Boutique.
final boutiqueExpenseBalanceProvider =
    FutureProvider.autoDispose<List<ExpenseBalanceData>>(
  (ref) async {
    final expenses = await ref.watch(storeControllerProvider).fetchExpenses();
    final adapter = BoutiqueExpenseBalanceAdapter();
    return adapter.convertToBalanceData(expenses);
  },
);

final reportDataProvider = FutureProvider.family.autoDispose<ReportData, ({
  ReportPeriod period,
  DateTime? startDate,
  DateTime? endDate,
})>((ref, params) async {
  return ref.watch(storeControllerProvider).getReportData(
        params.period,
        startDate: params.startDate,
        endDate: params.endDate,
      );
});

final salesReportProvider = FutureProvider.family.autoDispose<SalesReportData, ({
  ReportPeriod period,
  DateTime? startDate,
  DateTime? endDate,
})>((ref, params) async {
  return ref.watch(storeControllerProvider).getSalesReport(
        params.period,
        startDate: params.startDate,
        endDate: params.endDate,
      );
});

final purchasesReportProvider = FutureProvider.family.autoDispose<PurchasesReportData, ({
  ReportPeriod period,
  DateTime? startDate,
  DateTime? endDate,
})>((ref, params) async {
  return ref.watch(storeControllerProvider).getPurchasesReport(
        params.period,
        startDate: params.startDate,
        endDate: params.endDate,
      );
});

final expensesReportProvider = FutureProvider.family.autoDispose<ExpensesReportData, ({
  ReportPeriod period,
  DateTime? startDate,
  DateTime? endDate,
})>((ref, params) async {
  return ref.watch(storeControllerProvider).getExpensesReport(
        params.period,
        startDate: params.startDate,
        endDate: params.endDate,
      );
});

final profitReportProvider = FutureProvider.family.autoDispose<ProfitReportData, ({
  ReportPeriod period,
  DateTime? startDate,
  DateTime? endDate,
})>((ref, params) async {
  return ref.watch(storeControllerProvider).getProfitReport(
        params.period,
        startDate: params.startDate,
        endDate: params.endDate,
      );
});

