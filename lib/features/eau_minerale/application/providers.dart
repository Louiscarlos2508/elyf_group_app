import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_activity_repository.dart';
import '../data/repositories/mock_customer_repository.dart';
import '../data/repositories/mock_finance_repository.dart';
import '../data/repositories/mock_inventory_repository.dart';
import '../data/repositories/mock_product_repository.dart';
import '../data/repositories/mock_production_repository.dart';
import '../data/repositories/mock_sales_repository.dart';
import '../domain/repositories/activity_repository.dart';
import '../domain/repositories/customer_repository.dart';
import '../domain/repositories/finance_repository.dart';
import '../domain/repositories/inventory_repository.dart';
import '../domain/entities/product.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/production_repository.dart';
import '../domain/repositories/sales_repository.dart';
import 'controllers/activity_controller.dart';
import 'controllers/clients_controller.dart';
import 'controllers/finances_controller.dart';
import 'controllers/production_controller.dart';
import 'controllers/sales_controller.dart';
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

final activityStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(activityControllerProvider).fetchTodaySummary(),
);

final productionStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(productionControllerProvider).fetchTodayProductions(),
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

/// Enum used for bottom navigation in the module shell.
enum EauMineraleSection {
  activity,
  production,
  sales,
  stock,
  clients,
  finances,
  settings,
}
