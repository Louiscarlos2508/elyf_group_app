import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'repository_providers.dart';
import 'service_providers.dart';

// Controller Providers
final inventoryControllerProvider = Provider<InventoryController>(
  (ref) => InventoryController(ref.watch(inventoryRepositoryProvider)),
);

final productControllerProvider = Provider<ProductController>(
  (ref) => ProductController(ref.watch(productRepositoryProvider)),
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
  (ref) => StockController(
    ref.watch(inventoryRepositoryProvider),
    ref.watch(bobineStockQuantityRepositoryProvider),
    ref.watch(packagingStockRepositoryProvider),
    ref.watch(stockRepositoryProvider),
  ),
);

final productionSessionControllerProvider =
    Provider<ProductionSessionController>(
      (ref) => ProductionSessionController(
        ref.watch(productionSessionRepositoryProvider),
        ref.watch(stockControllerProvider),
        ref.watch(bobineStockQuantityRepositoryProvider),
      ),
    );

final salesControllerProvider = Provider<SalesController>(
  (ref) => SalesController(
    ref.watch(saleRepositoryProvider),
    ref.watch(saleServiceProvider),
  ),
);

final clientsControllerProvider = Provider<ClientsController>(
  (ref) => ClientsController(ref.watch(customerRepositoryProvider)),
);

final financesControllerProvider = Provider<FinancesController>(
  (ref) => FinancesController(ref.watch(financeRepositoryProvider)),
);

final salaryControllerProvider = Provider<SalaryController>(
  (ref) => SalaryController(ref.watch(salaryRepositoryProvider)),
);

final reportControllerProvider = Provider<ReportController>(
  (ref) => ReportController(ref.watch(reportRepositoryProvider)),
);
