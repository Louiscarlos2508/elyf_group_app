import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

export 'providers/permission_providers.dart';
export 'providers/section_providers.dart';
import '../../audit_trail/application/providers.dart';
import 'providers/permission_providers.dart' show currentUserIdProvider;
import '../../../../core/tenant/tenant_provider.dart'
    show activeEnterpriseProvider;

import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

import 'package:elyf_groupe_app/core/domain/entities/expense_balance_data.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/expense_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/closing_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/purchase_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/report_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/stock_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/product_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/sale_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/treasury_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/supplier_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/supplier_settlement_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/category_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/adapters/expense_balance_adapter.dart';
import '../domain/entities/product.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/stock_movement.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/stock_movement_repository.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/stock_movement_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/services/boutique_export_service.dart';
import 'package:elyf_groupe_app/features/boutique/domain/services/boutique_settings_service.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/report_data.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/expense_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/product_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/purchase_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/report_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/sale_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/stock_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/closing_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/treasury_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/supplier_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/supplier_settlement_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/category_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/purchase.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/expense.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/closing.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/supplier.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/category.dart';
import '../domain/services/calculation/cart_calculation_service.dart';
import '../domain/services/cart_service.dart';
import '../domain/services/boutique_calculation_service.dart';
import '../domain/services/product_calculation_service.dart';
import '../domain/services/product_filter_service.dart';
import '../domain/services/validation/product_validation_service.dart';
import '../domain/entities/boutique_settings.dart';
import '../domain/repositories/boutique_settings_repository.dart';
import '../data/repositories/boutique_settings_offline_repository.dart';
import '../domain/entities/cart_item.dart';
import 'controllers/cart_controller.dart';
import 'controllers/store_controller.dart';
import '../domain/services/supplier_settlement_service.dart';
import '../../../../core/printing/printer_provider.dart';

/// Provider for BoutiqueCalculationService.
final boutiqueCalculationServiceProvider =
    Provider<BoutiqueCalculationService>(
      (ref) => BoutiqueCalculationService(),
    );

/// Provider for ProductCalculationService.
final productCalculationServiceProvider = Provider<ProductCalculationService>(
  (ref) => ProductCalculationService(),
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
final cartServiceProvider = Provider<CartService>((ref) => CartService());

/// Provider for CartController (StateNotifier).
/// Keeps track of the cart items across the module.
final cartProvider = NotifierProvider<CartController, List<CartItem>>(() {
  return CartController();
});

/// Provider for ProductFilterService.
final productFilterServiceProvider = Provider<ProductFilterService>(
  (ref) => ProductFilterService(),
);

/// Provider for ProductOfflineRepository.
///
/// Requires active enterprise to be set.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return ProductOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'boutique',
    auditTrailRepository: ref.watch(auditTrailRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

/// Provider for SaleOfflineRepository.
///
/// Requires active enterprise to be set.
final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return SaleOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'boutique',
    auditTrailRepository: ref.watch(auditTrailRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => StockOfflineRepository(
    productRepository: ref.watch(productRepositoryProvider),
  ),
);

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return PurchaseOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'boutique',
    auditTrailRepository: ref.watch(auditTrailRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

/// Provider for ExpenseOfflineRepository.
///
/// Requires active enterprise to be set.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return ExpenseOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'boutique',
    auditTrailRepository: ref.watch(auditTrailRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

final closingRepositoryProvider = Provider<ClosingRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return ClosingOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'boutique',
    auditTrailRepository: ref.watch(auditTrailRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

final treasuryRepositoryProvider = Provider<TreasuryRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return TreasuryOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'boutique',
    auditTrailRepository: ref.watch(auditTrailRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return SupplierOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'boutique',
    auditTrailRepository: ref.watch(auditTrailRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

final settlementRepositoryProvider = Provider<SupplierSettlementRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return SupplierSettlementOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'boutique',
    auditTrailRepository: ref.watch(auditTrailRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

final supplierSettlementServiceProvider = Provider<SupplierSettlementService>((ref) {
  return SupplierSettlementService(
    purchaseRepository: ref.watch(purchaseRepositoryProvider),
    settlementRepository: ref.watch(settlementRepositoryProvider),
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return CategoryOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'boutique',
    auditTrailRepository: ref.watch(auditTrailRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportOfflineRepository(
    saleRepository: ref.watch(saleRepositoryProvider),
    purchaseRepository: ref.watch(purchaseRepositoryProvider),
    expenseRepository: ref.watch(expenseRepositoryProvider),
    supplierRepository: ref.watch(supplierRepositoryProvider),
    settlementRepository: ref.watch(settlementRepositoryProvider),
  );
});

final stockMovementRepositoryProvider = Provider<StockMovementRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return StockMovementOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'boutique',
    auditTrailRepository: ref.watch(auditTrailRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

final storeControllerProvider = Provider<StoreController>((ref) {
  return StoreController(
    ref.watch(productRepositoryProvider),
    ref.watch(saleRepositoryProvider),
    ref.watch(stockRepositoryProvider),
    ref.watch(purchaseRepositoryProvider),
    ref.watch(expenseRepositoryProvider),
    ref.watch(reportRepositoryProvider),
    ref.watch(closingRepositoryProvider),
    ref.watch(treasuryRepositoryProvider),
    ref.watch(supplierRepositoryProvider),
    ref.watch(settlementRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
    ref.watch(stockMovementRepositoryProvider),
    ref.watch(supplierSettlementServiceProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(currentUserIdProvider),
  );
});

final productsProvider = StreamProvider(
  (ref) => ref.watch(storeControllerProvider).watchProducts(),
);

final activeProductsProvider = Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
  return ref.watch(productsProvider).whenData(
    (products) => products.where((p) => p.isActive).toList(),
  );
});

final recentSalesProvider = StreamProvider(
  (ref) => ref.watch(storeControllerProvider).watchRecentSales().debounceTime(
        const Duration(milliseconds: 500),
      ),
);

final lowStockProductsProvider = StreamProvider.autoDispose(
  (ref) {
    final settings = ref.watch(boutiqueSettingsProvider).value;
    final threshold = settings?.lowStockThreshold ?? 5;
    return ref.watch(storeControllerProvider).watchLowStockProducts(
      threshold: threshold,
    );
  },
);

/// Reactive stream of boutique settings.
final boutiqueSettingsProvider = StreamProvider<BoutiqueSettings?>((ref) {
  final repository = ref.watch(boutiqueSettingsRepositoryProvider);
  final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  return repository.watchSettings(enterpriseId);
});

final purchasesProvider = StreamProvider(
  (ref) => ref.watch(storeControllerProvider).watchPurchases(),
);

final expensesProvider = StreamProvider(
  (ref) => ref.watch(storeControllerProvider).watchExpenses(),
);

final closingsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(storeControllerProvider).watchClosings(),
);

final activeSessionProvider = StreamProvider.autoDispose<Closing?>(
  (ref) => ref.watch(storeControllerProvider).watchActiveSession(),
);

final treasuryOperationsProvider = StreamProvider.autoDispose<List<TreasuryOperation>>(
  (ref) => ref.watch(storeControllerProvider).watchTreasuryOperations(),
);

final treasuryBalancesProvider = StreamProvider.autoDispose<Map<String, int>>(
  (ref) => ref.watch(storeControllerProvider).watchTreasuryBalances(),
);

// --- Suppliers ---

final suppliersProvider = StreamProvider.autoDispose<List<Supplier>>(
  (ref) => ref.watch(storeControllerProvider).watchSuppliers(),
);

final categoriesProvider = StreamProvider.autoDispose<List<Category>>(
  (ref) => ref.watch(storeControllerProvider).watchCategories(),
);

final stockValuationProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(storeControllerProvider).calculateStockValuation();
});

/// Provider combiné pour les métriques mensuelles du dashboard boutique.
///
/// Simplifie l'utilisation en combinant sales, purchases et expenses
/// en un seul AsyncValue.
final boutiqueMonthlyMetricsProvider = StreamProvider.autoDispose<
    ({List<Sale> sales, List<Purchase> purchases, List<Expense> expenses})>(
  (ref) {
    final controller = ref.watch(storeControllerProvider);
    return CombineLatestStream.combine3(
      controller.watchRecentSales(),
      controller.watchPurchases(),
      controller.watchExpenses(),
      (sales, purchases, expenses) => (
        sales: sales,
        purchases: purchases,
        expenses: expenses,
      ),
    ).debounceTime(const Duration(milliseconds: 500));
  },
);

/// Provider pour le bilan des dépenses Boutique.
final boutiqueExpenseBalanceProvider =
    StreamProvider.autoDispose<List<ExpenseBalanceData>>((ref) {
      return ref.watch(storeControllerProvider).watchExpenses().map((expenses) {
        final adapter = BoutiqueExpenseBalanceAdapter();
        return adapter.convertToBalanceData(expenses);
      });
    });

final reportDataProvider = StreamProvider.family
    .autoDispose<
      ReportData,
      ({ReportPeriod period, DateTime? startDate, DateTime? endDate})
    >((ref, params) {
      return ref
          .watch(storeControllerProvider)
          .watchReportData(
            params.period,
            startDate: params.startDate,
            endDate: params.endDate,
          );
    });

final salesReportProvider = StreamProvider.family
    .autoDispose<
      SalesReportData,
      ({ReportPeriod period, DateTime? startDate, DateTime? endDate})
    >((ref, params) {
      return ref
          .watch(storeControllerProvider)
          .watchSalesReport(
            params.period,
            startDate: params.startDate,
            endDate: params.endDate,
          );
    });

final purchasesReportProvider = StreamProvider.family
    .autoDispose<
      PurchasesReportData,
      ({ReportPeriod period, DateTime? startDate, DateTime? endDate})
    >((ref, params) {
      return ref
          .watch(storeControllerProvider)
          .watchPurchasesReport(
            params.period,
            startDate: params.startDate,
            endDate: params.endDate,
          );
    });

final expensesReportProvider = StreamProvider.family
    .autoDispose<
      ExpensesReportData,
      ({ReportPeriod period, DateTime? startDate, DateTime? endDate})
    >((ref, params) {
      return ref
          .watch(storeControllerProvider)
          .watchExpensesReport(
            params.period,
            startDate: params.startDate,
            endDate: params.endDate,
          );
    });

final profitReportProvider = StreamProvider.family
    .autoDispose<
      ProfitReportData,
      ({ReportPeriod period, DateTime? startDate, DateTime? endDate})
    >((ref, params) {
      return ref
          .watch(storeControllerProvider)
          .watchProfitReport(
            params.period,
            startDate: params.startDate,
            endDate: params.endDate,
          );
    });

final fullReportDataProvider = StreamProvider.family
    .autoDispose<
      FullBoutiqueReportData,
      ({ReportPeriod period, DateTime? startDate, DateTime? endDate})
    >((ref, params) {
      return ref
          .watch(storeControllerProvider)
          .watchFullReportData(
            params.period,
            startDate: params.startDate,
            endDate: params.endDate,
          );
    });

final debtsReportProvider = StreamProvider.autoDispose<DebtsReportData>((ref) {
  return ref.watch(storeControllerProvider).watchDebtsReport();
});

/// Provider for BoutiqueExportService.
final boutiqueExportServiceProvider = Provider<BoutiqueExportService>((ref) {
  return BoutiqueExportService();
});


/// Provider for BoutiqueSettingsRepository.
final boutiqueSettingsRepositoryProvider = Provider<BoutiqueSettingsRepository>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return BoutiqueSettingsOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    currentEnterpriseId: enterpriseId,
  );
});

/// Provider for BoutiqueSettingsService.
/// Note: Requires SharedPreferences to be initialized (usually via sharedPreferencesProvider from core).
final boutiqueSettingsServiceProvider = Provider<BoutiqueSettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final repository = ref.watch(boutiqueSettingsRepositoryProvider);
  final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id;
  return BoutiqueSettingsService(prefs, repository, enterpriseId);
});

final boutiquePrinterConfigProvider = Provider<PrinterConfig>((ref) {
  final settings = ref.watch(boutiqueSettingsServiceProvider);
  return PrinterConfig(
    type: settings.printerType,
    address: settings.printerConnection,
  );
});

final stockMovementsProvider = FutureProvider.family<List<StockMovement>, String?>((ref, productId) async {
  return ref.read(storeControllerProvider).fetchStockMovements(productId: productId);
});
