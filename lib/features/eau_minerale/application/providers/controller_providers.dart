import '../../../../core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/adapters/pack_stock_adapter.dart';
import '../adapters/no_op_pack_stock_adapter.dart';
import '../adapters/stock_controller_pack_adapter.dart';
import '../controllers/activity_controller.dart';
import '../controllers/bobine_stock_quantity_controller.dart';
import '../controllers/clients_controller.dart';
import '../controllers/finances_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/machine_controller.dart';
import '../controllers/packaging_stock_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/production_session_controller.dart';
import '../controllers/report_controller.dart';
import '../controllers/sales_controller.dart';
import '../controllers/salary_controller.dart';
import '../controllers/stock_controller.dart';
import '../controllers/supplier_controller.dart';
import '../controllers/purchase_controller.dart';
import '../controllers/closing_controller.dart';
import '../controllers/treasury_controller.dart';
import 'permission_providers.dart' show currentUserIdProvider;
import '../../../../core/tenant/tenant_provider.dart';
import '../../../../features/audit_trail/application/providers.dart';
import 'repository_providers.dart';

// Controller Providers
final inventoryControllerProvider = Provider<InventoryController>(
  (ref) => InventoryController(ref.watch(inventoryRepositoryProvider)),
);

final productControllerProvider = Provider<ProductController>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    return ProductController(
      ref.watch(eauMineraleProductRepositoryProvider),
      enterpriseId,
    );
  },
);

final activityControllerProvider = Provider<ActivityController>(
  (ref) => ActivityController(ref.watch(activityRepositoryProvider)),
);

final machineControllerProvider = Provider<MachineController>(
  (ref) => MachineController(ref.watch(machineRepositoryProvider)),
);

final bobineStockQuantityControllerProvider =
    Provider<BobineStockQuantityController>(
      (ref) => BobineStockQuantityController(
        ref.watch(bobineStockQuantityRepositoryProvider),
      ),
    );

final packagingStockControllerProvider = Provider<PackagingStockController>(
  (ref) =>
      PackagingStockController(ref.watch(packagingStockRepositoryProvider)),
);

final stockControllerProvider = Provider<StockController>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    return StockController(
      ref.watch(inventoryRepositoryProvider),
      ref.watch(bobineStockQuantityRepositoryProvider),
      ref.watch(packagingStockRepositoryProvider),
      ref.watch(stockRepositoryProvider),
      enterpriseId,
    );
  },
);

final packStockAdapterProvider = Provider<PackStockAdapter>((ref) {
  try {
    final controller = ref.watch(stockControllerProvider);
    return StockControllerPackAdapter(controller);
  } catch (e, st) {
    AppLogger.warning(
      'PackStockAdapter fallback to NoOp: $e',
      name: 'packStockAdapter',
      error: e,
      stackTrace: st,
    );
    return NoOpPackStockAdapter();
  }
});

final productionSessionControllerProvider =
    Provider<ProductionSessionController>(
      (ref) => ProductionSessionController(
        ref.watch(productionSessionRepositoryProvider),
        ref.watch(stockControllerProvider),
        ref.watch(bobineStockQuantityRepositoryProvider),
        ref.watch(eauMineraleProductRepositoryProvider),
        ref.watch(auditTrailServiceProvider),
      ),
    );

final salesControllerProvider = Provider<SalesController>(
  (ref) => SalesController(
    ref.watch(saleRepositoryProvider),
    ref.watch(packStockAdapterProvider),
    ref.watch(eauMineraleProductRepositoryProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(treasuryRepositoryProvider),
    ref.watch(closingRepositoryProvider),
  ),
);

final clientsControllerProvider = Provider<ClientsController>(
  (ref) => ClientsController(
    ref.watch(customerRepositoryProvider),
    ref.watch(creditRepositoryProvider),
  ),
);

final financesControllerProvider = Provider<FinancesController>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final userId = ref.watch(currentUserIdProvider) ?? 'unknown';

  return FinancesController(
    ref.watch(financeRepositoryProvider),
    ref.watch(treasuryRepositoryProvider),
    ref.watch(closingRepositoryProvider),
    enterpriseId,
    userId,
  );
});

final salaryControllerProvider = Provider<SalaryController>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
    final userId = ref.watch(currentUserIdProvider) ?? 'unknown';
    
    return SalaryController(
      ref.watch(salaryRepositoryProvider),
      productionSessionRepository: ref.watch(productionSessionRepositoryProvider),
      dailyWorkerRepository: ref.watch(dailyWorkerRepositoryProvider),
      treasuryRepository: ref.watch(treasuryRepositoryProvider),
      financeRepository: ref.watch(financeRepositoryProvider),
      enterpriseId: enterpriseId,
      userId: userId,
    );
  },
);

final reportControllerProvider = Provider<ReportController>(
  (ref) => ReportController(ref.watch(reportRepositoryProvider)),
);

final supplierControllerProvider = Provider<SupplierController>(
  (ref) => SupplierController(ref.watch(supplierRepositoryProvider)),
);

final purchaseControllerProvider = Provider<PurchaseController>(
  (ref) => PurchaseController(
    ref.watch(purchaseRepositoryProvider),
    ref.watch(stockRepositoryProvider),
    ref.watch(stockControllerProvider),
    ref.watch(treasuryRepositoryProvider),
    ref.watch(financeRepositoryProvider),
    ref.watch(supplierRepositoryProvider),
  ),
);

final closingControllerProvider = Provider<ClosingController>(
  (ref) => ClosingController(ref.watch(closingRepositoryProvider)),
);

final treasuryControllerProvider = Provider<TreasuryController>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final userId = ref.watch(currentUserIdProvider) ?? 'unknown';
    
    return TreasuryController(
      ref.watch(treasuryRepositoryProvider),
      enterpriseId,
      userId,
    );
  },
);
