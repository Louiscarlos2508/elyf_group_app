import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_expense_repository.dart';
import '../data/repositories/mock_product_repository.dart';
import '../data/repositories/mock_purchase_repository.dart';
import '../data/repositories/mock_report_repository.dart';
import '../data/repositories/mock_sale_repository.dart';
import '../data/repositories/mock_stock_repository.dart';
import '../domain/adapters/expense_balance_adapter.dart';
import '../domain/entities/report_data.dart';
import '../domain/repositories/expense_repository.dart';
import '../../../../core/domain/entities/expense_balance_data.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/purchase_repository.dart';
import '../domain/repositories/report_repository.dart';
import '../domain/repositories/sale_repository.dart';
import '../domain/repositories/stock_repository.dart';
import 'controllers/store_controller.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => MockProductRepository(),
);

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => MockSaleRepository(),
);

final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => MockStockRepository(ref.watch(productRepositoryProvider)),
);

final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) => MockPurchaseRepository(),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => MockExpenseRepository(),
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

