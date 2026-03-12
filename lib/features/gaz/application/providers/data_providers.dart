import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';

import '../../domain/entities/cylinder.dart';
import '../../domain/entities/cylinder_leak.dart';
import '../../domain/entities/cylinder_stock.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/financial_report.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/entities/gaz_employee.dart';
import '../../domain/entities/gaz_salary_payment.dart';
import '../../domain/entities/pos_remittance.dart';
import '../../domain/entities/site_logistics_record.dart';
import '../../domain/entities/stock_alert.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/wholesaler.dart';
import '../../domain/entities/gaz_settings.dart';
import '../../domain/entities/gaz_treasury_synthesis.dart';
import '../../domain/entities/gaz_inventory_audit.dart';

import 'repository_providers.dart';
import 'service_providers.dart';
import 'controller_providers.dart';
import 'ui_providers.dart';

final gazScopedEnterpriseIdsProvider = FutureProvider<List<String>>((ref) async {
  final activeEnterprise = await ref.watch(activeEnterpriseProvider.future);
  if (activeEnterprise == null) return [];

  final List<String> scopedIds = [activeEnterprise.id];

  if (activeEnterprise.type == EnterpriseType.gasCompany) {
    final allAccessibleEnterprises = await ref.watch(userAccessibleEnterprisesProvider.future);
    final childrenIds = allAccessibleEnterprises
        .where((e) => e.parentEnterpriseId == activeEnterprise.id || e.ancestorIds.contains(activeEnterprise.id))
        .map((e) => e.id);
    scopedIds.addAll(childrenIds);
  }

  return scopedIds.toSet().toList();
});

final gazSharedScopedEnterpriseIdsProvider = FutureProvider<List<String>>((ref) async {
  final activeEnterprise = await ref.watch(activeEnterpriseProvider.future);
  if (activeEnterprise == null) return [];

  final List<String> scopedIds = [activeEnterprise.id];

  if (activeEnterprise.isPointOfSale && activeEnterprise.parentEnterpriseId != null) {
    scopedIds.add(activeEnterprise.parentEnterpriseId!);
  }

  if (activeEnterprise.type == EnterpriseType.gasCompany) {
    final allAccessibleEnterprises = await ref.watch(userAccessibleEnterprisesProvider.future);
    final childrenIds = allAccessibleEnterprises
        .where((e) => e.parentEnterpriseId == activeEnterprise.id || e.ancestorIds.contains(activeEnterprise.id))
        .map((e) => e.id);
    scopedIds.addAll(childrenIds);
  }

  return scopedIds.toSet().toList();
});

final gazTreasuryBalanceProvider = FutureProvider.family<Map<String, int>, String>((ref, enterpriseId) {
  final repo = ref.watch(gazTreasuryRepositoryProvider);
  final scopedIds = ref.watch(gazScopedEnterpriseIdsProvider).value;
  return repo.getBalances(enterpriseId, enterpriseIds: scopedIds);
});

final gazTreasuryOperationsStreamProvider = StreamProvider.family<List<TreasuryOperation>, String>((ref, enterpriseId) {
  final repo = ref.watch(gazTreasuryRepositoryProvider);
  final scopedIds = ref.watch(gazScopedEnterpriseIdsProvider).value;
  return repo.watchOperations(enterpriseId, enterpriseIds: scopedIds);
});

final auditHistoryProvider = StreamProvider.family<List<GazInventoryAudit>, String>((ref, enterpriseId) {
  final repo = ref.watch(inventoryAuditRepositoryProvider(enterpriseId));
  return repo.watchAudits(enterpriseId);
});

final leakReportSummaryProvider = FutureProvider.family<Map<int, List<CylinderLeak>>, String>((ref, enterpriseId) {
  final controller = ref.watch(leakReportControllerProvider);
  return controller.getPendingLeaksSummary(enterpriseId);
});

final wholesalersProvider = FutureProvider<List<Wholesaler>>((ref) async {
  final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
  if (activeEnterprise == null) return [];
  final enterpriseId = activeEnterprise.id;
  final controller = ref.watch(wholesalerControllerProvider);
  return controller.getWholesalers(enterpriseId);
});

final cylindersProvider = StreamProvider.autoDispose<List<Cylinder>>((ref) {
  final controller = ref.watch(cylinderControllerProvider);
  final scopedIds = ref.watch(gazScopedEnterpriseIdsProvider).value;
  if (scopedIds != null && scopedIds.isNotEmpty) {
    return controller.watchCylindersForEnterprises(scopedIds);
  }
  return controller.watchCylinders();
});

final pointOfSaleCylindersProvider = StreamProvider.family<List<Cylinder>, ({String pointOfSaleId, String enterpriseId, String moduleId})>((ref, params) {
  final allCylindersAsync = ref.watch(cylindersProvider);
  final pointsOfSaleAsync = ref.watch(enterprisesByParentAndTypeProvider((parentId: params.enterpriseId, type: EnterpriseType.gasPointOfSale)));

  final allCylinders = allCylindersAsync.value ?? [];
  final pointsOfSale = pointsOfSaleAsync.value ?? [];

  final enterprisePos = pointsOfSale.where((pos) => pos.id == params.pointOfSaleId).firstOrNull;

  if (enterprisePos == null) return Stream.value([]);

  final cylinderIds = enterprisePos.metadata['cylinderIds'] as List<dynamic>? ?? [];
  final stringCylinderIds = cylinderIds.map((e) => e.toString()).toList();

  return Stream.value(allCylinders.where((c) => stringCylinderIds.contains(c.id)).toList());
});

final gasSalesProvider = StreamProvider<List<GasSale>>((ref) {
  final controller = ref.watch(gasControllerProvider);
  final viewType = ref.watch(gazDashboardViewTypeProvider);

  if (viewType == GazDashboardViewType.local) {
    final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
    return controller.watchSales(enterpriseIds: [activeId]);
  }

  final scopedIds = ref.watch(gazScopedEnterpriseIdsProvider).value;
  return controller.watchSales(enterpriseIds: scopedIds);
});

final gazExpensesProvider = StreamProvider<List<GazExpense>>((ref) {
  final controller = ref.watch(expenseControllerProvider);
  final viewType = ref.watch(gazDashboardViewTypeProvider);

  if (viewType == GazDashboardViewType.local) {
    final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
    return controller.watchExpenses(enterpriseIds: [activeId]);
  }

  final scopedIds = ref.watch(gazScopedEnterpriseIdsProvider).value;
  return controller.watchExpenses(enterpriseIds: scopedIds);
});

final gazStocksProvider = StreamProvider<List<CylinderStock>>((ref) {
  final controller = ref.watch(cylinderStockControllerProvider);
  final viewType = ref.watch(gazDashboardViewTypeProvider);
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';

  if (viewType == GazDashboardViewType.local) {
    return controller.watchStocks(activeId, enterpriseIds: [activeId]);
  }

  final scopedIds = ref.watch(gazScopedEnterpriseIdsProvider).value;
  return controller.watchStocks(activeId, enterpriseIds: scopedIds);
});

final gazPOSRemittancesProvider = StreamProvider<List<GazPOSRemittance>>((ref) {
  final repository = ref.watch(gazPOSRemittanceRepositoryProvider);
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? '';
  return repository.watchRemittances(activeId);
});

final cylinderStocksProvider = StreamProvider.family<List<CylinderStock>, ({String enterpriseId, CylinderStatus? status, String? siteId})>((ref, params) {
  final controller = ref.watch(cylinderStockControllerProvider);
  return controller.watchStocks(params.enterpriseId, status: params.status, siteId: params.siteId);
});

final cylinderLeaksProvider = StreamProvider.family<List<CylinderLeak>, ({String enterpriseId, LeakStatus? status})>((ref, params) {
  final controller = ref.watch(cylinderLeakControllerProvider);
  return controller.watchLeaks(params.enterpriseId, status: params.status);
});

final financialReportsProvider = StreamProvider.family<List<FinancialReport>, ({String enterpriseId, ReportPeriod? period, ReportStatus? status})>((ref, params) {
  final controller = ref.watch(financialReportControllerProvider);
  return controller.watchReports(params.enterpriseId, period: params.period, status: params.status);
});

final financialChargesProvider = FutureProvider.family<({double fixedCharges, double variableCharges, double salaries, double loadingEventExpenses, double totalExpenses}), ({String enterpriseId, DateTime startDate, DateTime endDate})>((ref, params) async {
  final service = ref.watch(financialCalculationServiceProvider);
  return service.calculateCharges(params.enterpriseId, params.startDate, params.endDate);
});

final gazStockHistoryProvider = FutureProvider.family<List<StockMovement>, ({String enterpriseId, DateTime startDate, DateTime endDate, String? siteId})>((ref, params) async {
  final service = ref.watch(gazStockReportServiceProvider);
  final viewType = ref.watch(gazDashboardViewTypeProvider);

  List<String> enterpriseIds;
  if (viewType == GazDashboardViewType.local) {
    enterpriseIds = [params.enterpriseId];
  } else {
    enterpriseIds = ref.watch(gazScopedEnterpriseIdsProvider).value ?? [params.enterpriseId];
  }

  return service.getStockHistory(enterpriseIds: enterpriseIds, startDate: params.startDate, endDate: params.endDate, siteId: params.siteId);
});

final gazStockSummaryProvider = FutureProvider.family<Map<int, Map<CylinderStatus, int>>, ({String enterpriseId, String? siteId})>((ref, params) async {
  final service = ref.watch(gazStockReportServiceProvider);
  final viewType = ref.watch(gazDashboardViewTypeProvider);

  List<String> enterpriseIds;
  if (viewType == GazDashboardViewType.local) {
    enterpriseIds = [params.enterpriseId];
  } else {
    enterpriseIds = ref.watch(gazScopedEnterpriseIdsProvider).value ?? [params.enterpriseId];
  }

  return service.getStockSummary(enterpriseIds: enterpriseIds, siteId: params.siteId);
});

final financialNetAmountProvider = FutureProvider.family<double, ({String enterpriseId, DateTime startDate, DateTime endDate, double totalRevenue})>((ref, params) async {
  final controller = ref.watch(financialReportControllerProvider);
  return controller.calculateNetAmount(params.enterpriseId, params.startDate, params.endDate, params.totalRevenue);
});

final allWholesalersProvider = StreamProvider.family<List<Wholesaler>, String>((ref, enterpriseId) {
  final service = ref.watch(wholesalerServiceProvider);
  return service.watchAllWholesalers(enterpriseId);
});

final tourProvider = StreamProvider.autoDispose.family<Tour?, String>((ref, tourId) {
  final repository = ref.watch(tourRepositoryProvider);
  final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';
  return repository.watchTours(enterpriseId).map((tours) => tours.where((t) => t.id == tourId).firstOrNull);
});

final toursStreamProvider = StreamProvider.family<List<Tour>, ({String enterpriseId, TourStatus? status})>((ref, params) {
  final repository = ref.watch(tourRepositoryProvider);
  return repository.watchTours(params.enterpriseId, status: params.status);
});

final tourLeaksProvider = StreamProvider.family<List<CylinderLeak>, String>((ref, tourId) {
  final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
  if (activeEnterprise == null) return const Stream.empty();
  final repository = ref.watch(cylinderLeakRepositoryProvider(activeEnterprise.id));
  return repository.watchLeaks(activeEnterprise.id).map((leaks) => leaks.where((l) => l.tourId == tourId).toList());
});

final tourFinanceProvider = StreamProvider.family<({double revenue, double expenses, double profit}), Tour>((ref, tour) {
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? '';
  final remittanceRepo = ref.watch(gazPOSRemittanceRepositoryProvider);
  final expenseRepo = ref.watch(gazExpenseRepositoryProvider);
  final settings = ref.watch(gazSettingsProvider((enterpriseId: activeId, moduleId: 'gaz'))).value;
  final purchasePrices = settings?.purchasePrices ?? {};

  return Rx.combineLatest2(remittanceRepo.watchRemittances(activeId), expenseRepo.watchExpenses(enterpriseIds: [activeId]), (List<GazPOSRemittance> remittances, List<GazExpense> expenses) {
    double revenue = tour.totalCashCollectedFromSites;
    final linkedRemittances = remittances.where((r) => r.tourId == tour.id && r.status == RemittanceStatus.validated);
    revenue += linkedRemittances.fold<double>(0, (sum, r) => sum + r.amount);
    double tourExpenses = tour.calculateTotalExpenses(purchasePrices);
    final linkedExpenses = expenses.where((e) => e.tourId == tour.id);
    tourExpenses += linkedExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    return (revenue: revenue, expenses: tourExpenses, profit: revenue - tourExpenses);
  });
});

final gazYearlyToursProvider = Provider<AsyncValue<List<Tour>>>((ref) {
  try {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    if (activeEnterprise == null) return const AsyncLoading();
    final allToursAsync = ref.watch(toursStreamProvider((enterpriseId: activeEnterprise.id, status: null)));
    return allToursAsync.when(data: (tours) {
      final now = DateTime.now();
      final yearStart = DateTime(now.year, 1, 1);
      final yearTours = tours.where((t) => !t.tourDate.isBefore(yearStart)).toList()..sort((a, b) => b.tourDate.compareTo(a.tourDate));
      if (yearTours.isEmpty && tours.isNotEmpty) return AsyncData(tours..sort((a, b) => b.tourDate.compareTo(a.tourDate)));
      return AsyncData(yearTours);
    }, loading: () => const AsyncLoading(), error: AsyncError.new);
  } catch (e, stackTrace) {
    return AsyncError(e, stackTrace);
  }
});

final gazSettingsProvider = StreamProvider.family<GazSettings?, ({String enterpriseId, String moduleId})>((ref, params) {
  final controller = ref.watch(gazSettingsControllerProvider(params.enterpriseId));
  return controller.watchSettings(enterpriseId: params.enterpriseId, moduleId: params.moduleId);
});

final gazEmployeesProvider = StreamProvider.family<List<GazEmployee>, String>((ref, enterpriseId) {
  final controller = ref.watch(gazEmployeeControllerProvider);
  return controller.watchEmployees(enterpriseId);
});

final gazSalaryPaymentsProvider = StreamProvider.family<List<GazSalaryPayment>, String>((ref, enterpriseId) {
  final controller = ref.watch(gazSalaryPaymentControllerProvider);
  return controller.watchPayments(enterpriseId);
});

final lowStockAlertsProvider = FutureProvider.family<List<StockAlert>, String>((ref, enterpriseId) async {
  final alertService = ref.watch(gasAlertServiceProvider);
  final cylindersAsync = ref.watch(cylindersProvider);
  return cylindersAsync.when(data: (cylinders) async {
    final alerts = <StockAlert>[];
    for (final cylinder in cylinders) {
      final alert = await alertService.checkStockLevel(enterpriseId: enterpriseId, cylinderId: cylinder.id, weight: cylinder.weight, status: CylinderStatus.full);
      if (alert != null) alerts.add(alert);
    }
    return alerts;
  }, loading: () => <StockAlert>[], error: (_, __) => <StockAlert>[]);
});

final gazHqSalesProvider = StreamProvider<List<GasSale>>((ref) {
  final controller = ref.watch(gasControllerProvider);
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  return controller.watchSales(enterpriseIds: [activeId]);
});

final posSalesProvider = StreamProvider.family<List<GasSale>, String>((ref, posId) {
  final controller = ref.watch(gasControllerProvider);
  return controller.watchSales(enterpriseIds: [posId]);
});

final gazClosedToursProvider = StreamProvider<List<Tour>>((ref) {
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final repository = ref.watch(tourRepositoryProvider);
  return repository.watchTours(activeId, status: TourStatus.closed);
});

final gazTreasurySynthesisProvider = StreamProvider<GazTreasurySynthesis>((ref) {
  final salesAsync = ref.watch(gazHqSalesProvider);
  final toursAsync = ref.watch(gazClosedToursProvider);
  final expensesAsync = ref.watch(gazExpensesProvider);
  final remittancesAsync = ref.watch(gazPOSRemittancesProvider);

  if (salesAsync is AsyncLoading || toursAsync is AsyncLoading || expensesAsync is AsyncLoading || remittancesAsync is AsyncLoading) {
    return const Stream.empty();
  }

  final sales = salesAsync.value ?? [];
  final tours = toursAsync.value ?? [];
  final expenses = expensesAsync.value ?? [];
  final remittances = remittancesAsync.value ?? [];

  final totalRevenue = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  final totalTourExpenses = tours.fold<double>(0, (sum, t) => sum + t.totalExpenses);
  final totalManualExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
  final totalPosRemittances = remittances.fold<double>(0, (sum, r) => sum + r.amount);

  return Stream.value(GazTreasurySynthesis(
    totalSalesRevenue: totalRevenue,
    totalTourExpenses: totalTourExpenses,
    totalManualExpenses: totalManualExpenses,
    totalPosRemittances: totalPosRemittances,
  ));
});

sealed class GazFinancialEvent {
  final DateTime date;
  final double amount;
  const GazFinancialEvent({required this.date, required this.amount});
}

class SaleEvent extends GazFinancialEvent {
  final List<GasSale> sales;
  SaleEvent({required super.date, required super.amount, required this.sales});
}

class RemittanceEvent extends GazFinancialEvent {
  final GazPOSRemittance remittance;
  RemittanceEvent({required super.date, required super.amount, required this.remittance});
}

final gazUnifiedFinancialEventsProvider = StreamProvider<List<GazFinancialEvent>>((ref) {
  final salesAsync = ref.watch(gasSalesProvider);
  final remittancesAsync = ref.watch(gazPOSRemittancesProvider);

  if (salesAsync is AsyncLoading || remittancesAsync is AsyncLoading) return const Stream.empty();

  final sales = salesAsync.value ?? [];
  final remittances = remittancesAsync.value ?? [];
  final events = <GazFinancialEvent>[];

  final Map<String, List<GasSale>> groupedSales = {};
  for (final sale in sales) {
    final key = sale.sessionId ?? '${sale.wholesalerId}_${sale.saleDate.year}${sale.saleDate.month}${sale.saleDate.day}${sale.saleDate.hour}${sale.saleDate.minute}';
    groupedSales.putIfAbsent(key, () => []).add(sale);
  }

  for (final group in groupedSales.values) {
    final totalAmount = group.fold<double>(0, (sum, s) => sum + s.totalAmount);
    events.add(SaleEvent(date: group.first.saleDate, amount: totalAmount, sales: group));
  }

  for (final remittance in remittances) {
    events.add(RemittanceEvent(date: remittance.remittanceDate, amount: remittance.amount, remittance: remittance));
  }

  events.sort((a, b) => b.date.compareTo(a.date));
  return Stream.value(events);
});

final gazReconciliationRecordsProvider = StreamProvider<List<GazSiteLogisticsRecord>>((ref) {
  final service = ref.watch(gazReconciliationServiceProvider);
  final activeEnterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? '';
  return service.watchReconciliationRecords(activeEnterpriseId);
});
