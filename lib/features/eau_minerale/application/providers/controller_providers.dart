import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../controllers/activity_controller.dart';
import '../controllers/clients_controller.dart';
import '../controllers/finances_controller.dart';
import '../controllers/machine_controller.dart';
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
import 'service_providers.dart';

// Controller Providers

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

final stockControllerProvider = Provider<StockController>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    return StockController(
      ref.watch(stockRepositoryProvider),
      ref.watch(eauMineraleProductRepositoryProvider),
      enterpriseId,
    );
  },
);



final productionSessionControllerProvider =
    Provider<ProductionSessionController>(
      (ref) => ProductionSessionController(
        ref.watch(productionSessionRepositoryProvider),
        ref.watch(auditTrailServiceProvider),
        ref.watch(machineMaterialCostServiceProvider),
        ref.watch(machineStockManagementServiceProvider),
      ),
    );

final salesControllerProvider = Provider<SalesController>(
  (ref) => SalesController(
    ref.watch(saleRepositoryProvider),
    ref.watch(stockControllerProvider),
    ref.watch(eauMineraleProductRepositoryProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(treasuryRepositoryProvider),
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
    final userId = ref.watch(currentUserIdProvider);
    
    return FinancesController(
      ref.watch(financeRepositoryProvider),
      ref.watch(treasuryRepositoryProvider),
      enterpriseId,
      userId,
    );
  }
);

final salaryControllerProvider = Provider<SalaryController>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
    final userId = ref.watch(currentUserIdProvider);
    
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
    final userId = ref.watch(currentUserIdProvider);
    
    return TreasuryController(
      ref.watch(treasuryRepositoryProvider),
      enterpriseId,
      userId,
    );
  },
);
