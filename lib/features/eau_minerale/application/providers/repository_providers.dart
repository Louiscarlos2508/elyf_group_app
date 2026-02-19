import '../../../../core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'permission_providers.dart' show currentUserIdProvider;

import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../../../../features/audit_trail/application/providers.dart';
import '../../data/repositories/activity_offline_repository.dart';
import '../../data/repositories/bobine_stock_quantity_offline_repository.dart';
import '../../data/repositories/credit_offline_repository.dart';
import '../../data/repositories/customer_offline_repository.dart';
import '../../data/repositories/daily_worker_offline_repository.dart';
import '../../data/repositories/finance_offline_repository.dart';
import '../../data/repositories/inventory_offline_repository.dart';
import '../../data/repositories/packaging_stock_offline_repository.dart';
import '../../data/repositories/report_offline_repository.dart';
import '../../data/repositories/salary_offline_repository.dart';
import '../../data/repositories/stock_offline_repository.dart';
import '../../data/repositories/machine_offline_repository.dart';
import '../../data/repositories/product_offline_repository.dart';
import '../../data/repositories/production_session_offline_repository.dart';
import '../../data/repositories/sale_offline_repository.dart';
import '../../data/repositories/supplier_offline_repository.dart';
import '../../data/repositories/purchase_offline_repository.dart';
import '../../data/repositories/closing_offline_repository.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/bobine_stock_quantity_repository.dart';
import '../../domain/repositories/credit_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/daily_worker_repository.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/machine_repository.dart';
import '../../domain/repositories/packaging_stock_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/production_session_repository.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/repositories/salary_repository.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/repositories/closing_repository.dart';
import '../../domain/repositories/treasury_repository.dart';
import '../../data/repositories/treasury_offline_repository.dart';

// Repository Providers
final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final enterpriseIdValue = ref.watch(activeEnterpriseIdProvider);
  final enterpriseId = enterpriseIdValue.value ?? 'default';
  
  AppLogger.debug(
    'Creating SaleRepository with enterpriseId: $enterpriseId (state: ${enterpriseIdValue.isLoading ? "loading" : "ready"})',
    name: 'repository_providers',
  );
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return SaleOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
  );
});

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return StockOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'eau_minerale',
    productRepository: ref.watch(eauMineraleProductRepositoryProvider),
  );
});

final creditRepositoryProvider = Provider<CreditRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final saleRepo = ref.watch(saleRepositoryProvider);

  return CreditOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'eau_minerale',
    saleRepository: saleRepo,
  );
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return InventoryOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'eau_minerale',
  );
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final saleRepo = ref.watch(saleRepositoryProvider);

  return CustomerOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    saleRepository: saleRepo,
  );
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final enterpriseIdValue = ref.watch(activeEnterpriseIdProvider);
  final enterpriseId = enterpriseIdValue.value ?? 'default';

  AppLogger.debug(
    'Creating FinanceRepository with enterpriseId: $enterpriseId',
    name: 'repository_providers',
  );
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return FinanceOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'eau_minerale',
  );
});

/// Product repository pour le module Eau Minérale.
/// Nom explicite pour éviter toute collision avec d'autres modules (ex. Boutique).
final eauMineraleProductRepositoryProvider =
    Provider<ProductRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return ProductOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
  );
});


final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final saleRepo = ref.watch(saleRepositoryProvider);
  final sessionRepo = ref.watch(productionSessionRepositoryProvider);
  final creditRepo = ref.watch(creditRepositoryProvider);

  return ActivityOfflineRepository(
    saleRepository: saleRepo,
    productionSessionRepository: sessionRepo,
    creditRepository: creditRepo,
  );
});

final productionSessionRepositoryProvider =
    Provider<ProductionSessionRepository>((ref) {
      final enterpriseIdValue = ref.watch(activeEnterpriseIdProvider);
      final enterpriseId = enterpriseIdValue.value ?? 'default';

      AppLogger.debug(
        'Creating ProductionSessionRepository with enterpriseId: $enterpriseId',
        name: 'repository_providers',
      );
      final driftService = DriftService.instance;
      final syncManager = ref.watch(syncManagerProvider);
      final connectivityService = ref.watch(connectivityServiceProvider);

      return ProductionSessionOfflineRepository(
        driftService: driftService,
        syncManager: syncManager,
        connectivityService: connectivityService,
        enterpriseId: enterpriseId,
      );
    });

final machineRepositoryProvider = Provider<MachineRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return MachineOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
  );
});

final bobineStockQuantityRepositoryProvider =
    Provider<BobineStockQuantityRepository>((ref) {
      final enterpriseId =
          ref.watch(activeEnterpriseIdProvider).value ?? 'default';
      final driftService = DriftService.instance;
      final syncManager = ref.watch(syncManagerProvider);
      final connectivityService = ref.watch(connectivityServiceProvider);

      return BobineStockQuantityOfflineRepository(
        driftService: driftService,
        syncManager: syncManager,
        connectivityService: connectivityService,
        enterpriseId: enterpriseId,
      );
    });

final packagingStockRepositoryProvider = Provider<PackagingStockRepository>((
  ref,
) {
  final enterpriseId =
      ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return PackagingStockOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'eau_minerale',
  );
});

final dailyWorkerRepositoryProvider = Provider<DailyWorkerRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return DailyWorkerOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'eau_minerale',
  );
});

final salaryRepositoryProvider = Provider<SalaryRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return SalaryOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'eau_minerale',
  );
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final saleRepo = ref.watch(saleRepositoryProvider);
  final sessionRepo = ref.watch(productionSessionRepositoryProvider);
  final financeRepo = ref.watch(financeRepositoryProvider);
  final salaryRepo = ref.watch(salaryRepositoryProvider);
  final creditRepo = ref.watch(creditRepositoryProvider);

  return ReportOfflineRepository(
    saleRepository: saleRepo,
    productionSessionRepository: sessionRepo,
    financeRepository: financeRepo,
    salaryRepository: salaryRepo,
    creditRepository: creditRepo,
  );
});

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final auditTrailRepo = ref.watch(auditTrailRepositoryProvider);
  return SupplierOfflineRepository(
    driftService: DriftService.instance,
    syncManager: ref.watch(syncManagerProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    enterpriseId: enterpriseId,
    auditTrailRepository: auditTrailRepo,
  );
});

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final auditTrailRepo = ref.watch(auditTrailRepositoryProvider);
  return PurchaseOfflineRepository(
    driftService: DriftService.instance,
    syncManager: ref.watch(syncManagerProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    enterpriseId: enterpriseId,
    auditTrailRepository: auditTrailRepo,
  );
});

final closingRepositoryProvider = Provider<ClosingRepository>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final auditTrailRepo = ref.watch(auditTrailRepositoryProvider);
  return ClosingOfflineRepository(
    driftService: DriftService.instance,
    syncManager: ref.watch(syncManagerProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    enterpriseId: enterpriseId,
    auditTrailRepository: auditTrailRepo,
  );
});

final treasuryRepositoryProvider = Provider<TreasuryRepository>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final auditTrailRepo = ref.watch(auditTrailRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return TreasuryOfflineRepository(
    driftService: DriftService.instance,
    syncManager: ref.watch(syncManagerProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    enterpriseId: enterpriseId,
    moduleType: 'eau_minerale',
    auditTrailRepository: auditTrailRepo,
    userId: userId ?? 'unknown',
  );
});
