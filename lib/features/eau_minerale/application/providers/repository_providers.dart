import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../../data/repositories/customer_offline_repository.dart';
import '../../data/repositories/mock_activity_repository.dart';
import '../../data/repositories/mock_bobine_stock_quantity_repository.dart';
import '../../data/repositories/mock_credit_repository.dart';
import '../../data/repositories/mock_daily_worker_repository.dart';
import '../../data/repositories/mock_finance_repository.dart';
import '../../data/repositories/mock_inventory_repository.dart';
import '../../data/repositories/mock_packaging_stock_repository.dart';
import '../../data/repositories/mock_report_repository.dart';
import '../../data/repositories/mock_salary_repository.dart';
import '../../data/repositories/mock_stock_repository.dart';
import '../../data/repositories/machine_offline_repository.dart';
import '../../data/repositories/product_offline_repository.dart';
import '../../data/repositories/production_session_offline_repository.dart';
import '../../data/repositories/sale_offline_repository.dart';
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

// Repository Providers
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
    );
  },
);

final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => MockStockRepository(
    ref.watch(inventoryRepositoryProvider),
    ref.watch(productRepositoryProvider),
  ),
);

final creditRepositoryProvider = Provider<CreditRepository>(
  (ref) => MockCreditRepository(ref.watch(saleRepositoryProvider)),
);

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => MockInventoryRepository(),
);

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
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
  },
);

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => MockFinanceRepository(),
);

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
    );
  },
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => MockActivityRepository(),
);

final productionSessionRepositoryProvider =
    Provider<ProductionSessionRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return ProductionSessionOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
    );
  },
);

final machineRepositoryProvider = Provider<MachineRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return MachineOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
    );
  },
);

final bobineStockQuantityRepositoryProvider = Provider<BobineStockQuantityRepository>(
  (ref) => MockBobineStockQuantityRepository(),
);

final packagingStockRepositoryProvider = Provider<PackagingStockRepository>(
  (ref) => MockPackagingStockRepository(),
);

final dailyWorkerRepositoryProvider = Provider<DailyWorkerRepository>(
  (ref) => MockDailyWorkerRepository(),
);

final salaryRepositoryProvider = Provider<SalaryRepository>(
  (ref) => MockSalaryRepository(),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => MockReportRepository(
    salesRepository: ref.watch(saleRepositoryProvider),
    financeRepository: ref.watch(financeRepositoryProvider),
    salaryRepository: ref.watch(salaryRepositoryProvider),
    productionSessionRepository: ref.watch(productionSessionRepositoryProvider),
  ),
);

