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
import '../../../audit_trail/application/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
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
        ref.watch(auditTrailServiceProvider),
      ),
    );

final salesControllerProvider = Provider<SalesController>(
  (ref) => SalesController(
    ref.watch(saleRepositoryProvider),
    ref.watch(packStockAdapterProvider),
    ref.watch(eauMineraleProductRepositoryProvider),
    ref.watch(auditTrailServiceProvider),
  ),
);

final clientsControllerProvider = Provider<ClientsController>(
  (ref) => ClientsController(ref.watch(customerRepositoryProvider)),
);

final financesControllerProvider = Provider<FinancesController>(
  (ref) => FinancesController(ref.watch(financeRepositoryProvider)),
);

final salaryControllerProvider = Provider<SalaryController>(
  (ref) => SalaryController(
    ref.watch(salaryRepositoryProvider),
    productionSessionRepository: ref.watch(productionSessionRepositoryProvider),
    dailyWorkerRepository: ref.watch(dailyWorkerRepositoryProvider),
  ),
);

final reportControllerProvider = Provider<ReportController>(
  (ref) => ReportController(ref.watch(reportRepositoryProvider)),
);
