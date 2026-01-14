import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/entities/expense_balance_data.dart';
import '../../domain/adapters/expense_balance_adapter.dart';
import '../../domain/entities/daily_worker.dart';
import '../../domain/entities/electricity_meter_type.dart';
import '../../domain/entities/expense_report_data.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_sales_summary.dart';
import '../../domain/entities/production_report_data.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/salary_report_data.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/stock_movement.dart';
import 'controller_providers.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

/// Provider pour récupérer le type de compteur configuré
final electricityMeterTypeProvider =
    FutureProvider.autoDispose<ElectricityMeterType>(
      (ref) async =>
          ref.watch(electricityMeterConfigServiceProvider).getMeterType(),
    );

/// Provider pour récupérer toutes les machines (sans filtre).
final allMachinesProvider = FutureProvider.autoDispose<List<Machine>>((
  ref,
) async {
  return ref.read(machineControllerProvider).fetchMachines();
});

/// Provider pour récupérer tous les ouvriers journaliers.
final allDailyWorkersProvider = FutureProvider.autoDispose<List<DailyWorker>>((
  ref,
) async {
  return ref.read(dailyWorkerRepositoryProvider).fetchAllWorkers();
});

final activityStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(activityControllerProvider).fetchTodaySummary(),
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

/// Provider pour le bilan des dépenses Eau Minérale.
final eauMineraleExpenseBalanceProvider =
    FutureProvider.autoDispose<List<ExpenseBalanceData>>((ref) async {
      final expenses = await ref
          .read(financesControllerProvider)
          .fetchRecentExpenses();
      final adapter = EauMineraleExpenseBalanceAdapter();
      return adapter.convertToBalanceData(expenses.expenses);
    });

final productsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) async => ref.watch(productControllerProvider).fetchProducts(),
);

final productionPeriodConfigProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(productionPeriodServiceProvider).getConfig(),
);

/// Paramètres pour filtrer les mouvements de stock
class StockMovementFiltersParams {
  const StockMovementFiltersParams({
    this.startDate,
    this.endDate,
    this.type,
    this.productName,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final StockMovementType? type;
  final String? productName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementFiltersParams &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          type == other.type &&
          productName == other.productName;

  @override
  int get hashCode =>
      startDate.hashCode ^
      endDate.hashCode ^
      type.hashCode ^
      productName.hashCode;
}

/// Provider pour récupérer tous les mouvements de stock (bobines, emballages) avec filtres optionnels.
final stockMovementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, StockMovementFiltersParams>((
      ref,
      params,
    ) async {
      final controller = ref.read(stockControllerProvider);
      return await controller.fetchAllMovements(
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

final productionSessionsStateProvider =
    FutureProvider.autoDispose<List<ProductionSession>>((ref) async {
      return ref.read(productionSessionControllerProvider).fetchSessions();
    });

/// Provider pour récupérer une session par son ID.
final productionSessionDetailProvider = FutureProvider.autoDispose
    .family<ProductionSession, String>((ref, sessionId) async {
      final session = await ref
          .read(productionSessionControllerProvider)
          .fetchSessionById(sessionId);
      if (session == null) {
        throw Exception('Session non trouvée: $sessionId');
      }
      return session;
    });

/// Provider pour récupérer les ventes liées à une session.
final ventesParSessionProvider = FutureProvider.autoDispose
    .family<List<Sale>, String>((ref, sessionId) async {
      // Pour l'instant, on filtre les ventes par date de la session
      final session = await ref.read(
        productionSessionDetailProvider((sessionId)).future,
      );
      final allSales = await ref
          .read(saleRepositoryProvider)
          .fetchRecentSales();

      // Filtrer les ventes du même jour que la session
      return allSales.where((sale) {
        final saleDate = DateTime(
          sale.date.year,
          sale.date.month,
          sale.date.day,
        );
        final sessionDate = DateTime(
          session.date.year,
          session.date.month,
          session.date.day,
        );
        return saleDate == sessionDate;
      }).toList();
    });

final salaryStateProvider = FutureProvider.autoDispose(
  (ref) async => ref.watch(salaryControllerProvider).fetchSalaries(),
);

final reportDataProvider = FutureProvider.autoDispose
    .family<ReportData, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchReportData(period),
    );

final reportSalesProvider = FutureProvider.autoDispose
    .family<List<Sale>, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchSalesForPeriod(period),
    );

final reportProductSummaryProvider = FutureProvider.autoDispose
    .family<List<ProductSalesSummary>, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchProductSalesSummary(period),
    );

final reportProductionProvider = FutureProvider.autoDispose
    .family<ProductionReportData, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchProductionReport(period),
    );

final reportExpenseProvider = FutureProvider.autoDispose
    .family<ExpenseReportData, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchExpenseReport(period),
    );

final reportSalaryProvider = FutureProvider.autoDispose
    .family<SalaryReportData, ReportPeriod>(
      (ref, period) async =>
          ref.watch(reportControllerProvider).fetchSalaryReport(period),
    );
