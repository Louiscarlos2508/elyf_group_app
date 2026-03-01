import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'providers/permission_providers.dart';
export 'providers/section_providers.dart';
import '../../audit_trail/application/providers.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
export 'controllers/cylinder_controller.dart';
export 'controllers/cylinder_leak_controller.dart';
export 'controllers/cylinder_stock_controller.dart';
export 'controllers/expense_controller.dart';
export 'controllers/financial_report_controller.dart';
export 'controllers/gas_controller.dart';
export 'controllers/gaz_settings_controller.dart';
export 'controllers/gaz_session_controller.dart';

export 'controllers/stock_transfer_controller.dart';
export 'controllers/tour_controller.dart';
export 'controllers/wholesaler_controller.dart';
export 'controllers/leak_report_controller.dart';

import 'controllers/cylinder_controller.dart';
import 'controllers/cylinder_leak_controller.dart';
import 'controllers/cylinder_stock_controller.dart';
import 'controllers/expense_controller.dart';
import 'controllers/financial_report_controller.dart';
import 'controllers/gas_controller.dart';
import 'controllers/gaz_settings_controller.dart';
import 'controllers/gaz_session_controller.dart';

import 'controllers/stock_transfer_controller.dart';
import 'controllers/tour_controller.dart';
import 'controllers/wholesaler_controller.dart';
import 'controllers/leak_report_controller.dart';
import '../data/repositories/cylinder_leak_offline_repository.dart';
import '../data/repositories/cylinder_stock_offline_repository.dart';
import '../data/repositories/expense_offline_repository.dart';
import '../data/repositories/financial_report_offline_repository.dart';
import '../data/repositories/gas_offline_repository.dart';
import '../data/repositories/exchange_offline_repository.dart';
import '../data/repositories/gaz_settings_offline_repository.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import '../data/repositories/session_offline_repository.dart';
import '../data/repositories/stock_transfer_offline_repository.dart';
import '../data/repositories/tour_offline_repository.dart';
import '../data/repositories/wholesaler_offline_repository.dart';
import '../data/repositories/treasury_offline_repository.dart';
import '../data/repositories/collection_offline_repository.dart';
import '../domain/repositories/inventory_audit_repository.dart';
import '../data/repositories/inventory_audit_offline_repository.dart';
import '../domain/entities/gaz_inventory_audit.dart';
import '../domain/entities/cylinder.dart';
import '../domain/entities/cylinder_leak.dart';
import '../domain/entities/stock_movement.dart';
import '../domain/entities/cylinder_stock.dart';
import '../domain/entities/expense.dart';
import '../domain/entities/financial_report.dart';
import '../domain/entities/gas_sale.dart';
import '../domain/entities/stock_alert.dart';
import '../domain/entities/gaz_settings.dart';
import '../domain/entities/report_data.dart';
import '../domain/entities/stock_transfer.dart';
import '../domain/entities/tour.dart';
import '../domain/entities/wholesaler.dart';
import '../domain/entities/gaz_session.dart';
import '../domain/entities/collection.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import '../domain/services/leak_report_service.dart';
import '../domain/services/wholesaler_service.dart';
import '../domain/repositories/cylinder_leak_repository.dart';
import '../domain/repositories/cylinder_stock_repository.dart';
import '../domain/repositories/expense_repository.dart';
import '../domain/repositories/financial_report_repository.dart';
import '../domain/repositories/gas_repository.dart';
import '../domain/repositories/exchange_repository.dart';
import '../domain/repositories/gaz_settings_repository.dart';

import '../domain/repositories/session_repository.dart';
import '../domain/repositories/stock_transfer_repository.dart';
import '../domain/repositories/tour_repository.dart';
import '../domain/repositories/wholesaler_repository.dart';
import '../domain/repositories/treasury_repository.dart';
import '../domain/repositories/collection_repository.dart';
import '../domain/services/data_consistency_service.dart';
import '../domain/services/financial_calculation_service.dart';

import '../domain/services/gas_alert_service.dart';
import '../domain/services/gas_validation_service.dart';
import '../domain/services/filtering/gaz_filter_service.dart';
import '../domain/services/gaz_dashboard_calculation_service.dart';

import '../domain/services/gaz_report_calculation_service.dart';
import '../domain/services/gaz_stock_report_service.dart';
import '../domain/services/realtime_sync_service.dart';
import '../domain/services/stock_service.dart';
import '../domain/services/stock_transfer_service.dart';
import '../domain/services/tour_service.dart';
import '../domain/services/transaction_service.dart';
import '../domain/services/gaz_printing_service.dart';
import 'package:elyf_groupe_app/core/printing/printer_provider.dart';

/// Provider for GazDashboardCalculationService.
final gazDashboardCalculationServiceProvider =
    Provider<GazDashboardCalculationService>(
      (ref) => GazDashboardCalculationService(),
    );

/// Provider for GazReportCalculationService.
final gazReportCalculationServiceProvider =
    Provider<GazReportCalculationService>(
      (ref) => GazReportCalculationService(),
    );

/// Provider for GazFilterService.
final gazFilterServiceProvider = Provider<GazFilterService>(
  (ref) => GazFilterService(),
);

/// Provider for GasAlertService.
final gasAlertServiceProvider = Provider<GasAlertService>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final settingsRepo = ref.watch(gazSettingsRepositoryProvider(enterpriseId));
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  return GasAlertService(
    settingsRepository: settingsRepo,
    stockRepository: stockRepo,
  );
});

/// Provider for GasValidationService.
final gasValidationServiceProvider = Provider<GasValidationService>(
  (ref) => GasValidationService(),
);

/// Provider for WholesalerService.
final wholesalerServiceProvider = Provider<WholesalerService>((ref) {
  final gasRepository = ref.watch(gasRepositoryProvider);
  final wholesalerRepository = ref.watch(wholesalerRepositoryProvider);
  return WholesalerService(
    gasRepository: gasRepository,
    wholesalerRepository: wholesalerRepository,
  );
});

final leakReportServiceProvider = Provider<LeakReportService>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final leakRepository = ref.watch(
    cylinderLeakRepositoryProvider(enterpriseId),
  );
  return LeakReportService(leakRepository: leakRepository);
});

/// Provider for GazPrintingService.
final gazPrintingServiceProvider = Provider<GazPrintingService>((ref) {
  final printerService = ref.watch(activePrinterProvider);
  return GazPrintingService(printerService: printerService);
});
// Repositories

/// Scoped enterprise IDs for Gaz module data access.
/// Returns the active enterprise ID and all its children if it's a mother company.
final gazScopedEnterpriseIdsProvider = FutureProvider<List<String>>((
  ref,
) async {
  final activeEnterprise = await ref.watch(activeEnterpriseProvider.future);
  if (activeEnterprise == null) return [];

  final List<String> scopedIds = [activeEnterprise.id];

  // If the active enterprise is a mother company, include all its children
  if (activeEnterprise.type == EnterpriseType.gasCompany) {
    final allAccessibleEnterprises = await ref.watch(
      userAccessibleEnterprisesProvider.future,
    );
    final childrenIds = allAccessibleEnterprises
        .where(
          (e) =>
              e.parentEnterpriseId == activeEnterprise.id ||
              e.ancestorIds.contains(activeEnterprise.id),
        )
        .map((e) => e.id);
    scopedIds.addAll(childrenIds);
  }

  return scopedIds.toSet().toList();
});

final gasRepositoryProvider = Provider<GasRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final cylinderStockRepository = ref.watch(cylinderStockRepositoryProvider);

  return GasOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    cylinderStockRepository: cylinderStockRepository,
  );
});

final gasCylinderRepositoryProvider = Provider<GasRepository>((ref) {
  final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
  final enterpriseId = (activeEnterprise?.isPointOfSale == true && activeEnterprise?.type.module == EnterpriseModule.gaz)
      ? (activeEnterprise?.parentEnterpriseId ?? activeEnterprise?.id ?? 'default')
      : (activeEnterprise?.id ?? 'default');
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final cylinderStockRepository = ref.watch(cylinderStockRepositoryProvider);

  return GasOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    cylinderStockRepository: cylinderStockRepository,
  );
});

final gazExpenseRepositoryProvider = Provider<GazExpenseRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return GazExpenseOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'gaz',
  );
});

final gazTreasuryRepositoryProvider = Provider<GazTreasuryRepository>((ref) {
  final drift = ref.watch(driftServiceProvider);
  final sync = ref.watch(syncManagerProvider);
  return GazTreasuryOfflineRepository(drift.db, sync);
});

final gazTreasuryBalanceProvider =
    FutureProvider.family<Map<String, int>, String>((ref, enterpriseId) {
      final repo = ref.watch(gazTreasuryRepositoryProvider);
      final scopedIds = ref.watch(gazScopedEnterpriseIdsProvider).value;
      return repo.getBalances(enterpriseId, enterpriseIds: scopedIds);
    });

final gazTreasuryOperationsStreamProvider =
    StreamProvider.family<List<TreasuryOperation>, String>((ref, enterpriseId) {
      final repo = ref.watch(gazTreasuryRepositoryProvider);
      final scopedIds = ref.watch(gazScopedEnterpriseIdsProvider).value;
      return repo.watchOperations(enterpriseId, enterpriseIds: scopedIds);
    });

/// Provider for GazSessionRepository.
final gazSessionRepositoryProvider = Provider<GazSessionRepository>((ref) {
  final driftService = ref.watch(driftServiceProvider);
  return GazSessionOfflineRepository(driftService.db);
});

final cylinderStockRepositoryProvider = Provider<CylinderStockRepository>((
  ref,
) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return CylinderStockOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'gaz',
  );
});

final cylinderLeakRepositoryProvider =
    Provider.family<CylinderLeakRepository, String>((ref, enterpriseId) {
      final driftService = DriftService.instance;
      final syncManager = ref.watch(syncManagerProvider);
      final connectivityService = ref.watch(connectivityServiceProvider);

      return CylinderLeakOfflineRepository(
        driftService: driftService,
        syncManager: syncManager,
        connectivityService: connectivityService,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );
    });
// final gazDispatchServiceProvider = Provider<GazDispatchService>((ref) {
//   final gasRepo = ref.watch(gasRepositoryProvider);
//   final auditRepo = ref.watch(auditTrailRepositoryProvider);
//   return GazDispatchService(
//     gasRepository: gasRepo,
//     auditTrailRepository: auditRepo,
//   );
// });

/// Provider for ExchangeRepository.
final exchangeRepositoryProvider = Provider.family<ExchangeRepository, String>((
  ref,
  enterpriseId,
) {
  final drift = ref.watch(driftServiceProvider);
  final sync = ref.watch(syncManagerProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  // final auth = ref.watch(activeEnterpriseProvider).value;
  // final enterpriseId = auth?.id ?? ''; // This is now passed as a family parameter

  return ExchangeOfflineRepository(
    driftService: drift,
    syncManager: sync,
    connectivityService: connectivity,
    enterpriseId: enterpriseId,
  );
});

final tourRepositoryProvider = Provider<TourRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return TourOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'gaz',
  );
});

final wholesalerRepositoryProvider = Provider<WholesalerRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return WholesalerOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
  );
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final driftService = ref.watch(driftServiceProvider);
  final syncManager = ref.watch(syncManagerProvider);
  return CollectionOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
  );
});

final gazSettingsRepositoryProvider =
    Provider.family<GazSettingsRepository, String>((ref, enterpriseId) {
      final driftService = DriftService.instance;
      final syncManager = ref.watch(syncManagerProvider);
      final connectivityService = ref.watch(connectivityServiceProvider);

      return GazSettingsOfflineRepository(
        driftService: driftService,
        syncManager: syncManager,
        connectivityService: connectivityService,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );
    });

final financialReportRepositoryProvider = Provider<FinancialReportRepository>((
  ref,
) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return FinancialReportOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    moduleType: 'gaz',
  );
});

final stockTransferRepositoryProvider = Provider<StockTransferRepository>((
  ref,
) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return StockTransferOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    currentEnterpriseId: enterpriseId,
  );
});

// Services
final financialCalculationServiceProvider =
    Provider<FinancialCalculationService>((ref) {
      final expenseRepo = ref.watch(gazExpenseRepositoryProvider);
      return FinancialCalculationService(expenseRepository: expenseRepo);
    });

final stockServiceProvider = Provider<StockService>((ref) {
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  return StockService(stockRepository: stockRepo);
});

final tourServiceProvider = Provider<TourService>((ref) {
  final tourRepo = ref.watch(tourRepositoryProvider);
  final transactionService = ref.watch(transactionServiceProvider);
  return TourService(
    tourRepository: tourRepo,
    transactionService: transactionService,
  );
});

final stockTransferServiceProvider = Provider<StockTransferService>((ref) {
  final transferRepo = ref.watch(stockTransferRepositoryProvider);
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  final gasRepo = ref.watch(gasRepositoryProvider);
  final auditRepo = ref.watch(auditTrailRepositoryProvider);
  final enterpriseRepo = ref.watch(enterpriseRepositoryProvider);
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final settingsRepo = ref.watch(gazSettingsRepositoryProvider(enterpriseId));

  return StockTransferService(
    transferRepository: transferRepo,
    stockRepository: stockRepo,
    gasRepository: gasRepo,
    auditTrailRepository: auditRepo,
    enterpriseRepository: enterpriseRepo,
    settingsRepository: settingsRepo,
  );
});

// Data Consistency & Transaction Services
final dataConsistencyServiceProvider = Provider<DataConsistencyService>((ref) {
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  final gasRepo = ref.watch(gasRepositoryProvider);
  final tourRepo = ref.watch(tourRepositoryProvider);
  return DataConsistencyService(
    stockRepository: stockRepo,
    gasRepository: gasRepo,
    tourRepository: tourRepo,
  );
});

final inventoryAuditRepositoryProvider =
    Provider.family<GazInventoryAuditRepository, String>((ref, enterpriseId) {
      return GazInventoryAuditOfflineRepository(
        driftService: ref.watch(driftServiceProvider),
        syncManager: ref.watch(syncManagerProvider),
        connectivityService: ref.watch(connectivityServiceProvider),
        enterpriseId: enterpriseId,
      );
    });

final auditHistoryProvider =
    StreamProvider.family<List<GazInventoryAudit>, String>((ref, enterpriseId) {
      final repo = ref.watch(inventoryAuditRepositoryProvider(enterpriseId));
      return repo.watchAudits(enterpriseId);
    });

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  final gasRepo = ref.watch(gasRepositoryProvider);
  final tourRepo = ref.watch(tourRepositoryProvider);
  final consistencyService = ref.watch(dataConsistencyServiceProvider);
  final auditRepo = ref.watch(auditTrailRepositoryProvider);
  final alertService = ref.watch(gasAlertServiceProvider);
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final leakRepo = ref.watch(cylinderLeakRepositoryProvider(enterpriseId));
  final exchangeRepo = ref.watch(exchangeRepositoryProvider(enterpriseId));
  final settingsRepo = ref.watch(gazSettingsRepositoryProvider(enterpriseId));
  final inventoryAuditRepo = ref.watch(
    inventoryAuditRepositoryProvider(enterpriseId),
  );
  final expenseRepo = ref.watch(gazExpenseRepositoryProvider);
  final sessionRepo = ref.watch(gazSessionRepositoryProvider);
  final treasuryRepo = ref.watch(gazTreasuryRepositoryProvider);
  final collectionRepo = ref.watch(collectionRepositoryProvider);

  return TransactionService(
    stockRepository: stockRepo,
    gasRepository: gasRepo,
    tourRepository: tourRepo,
    consistencyService: consistencyService,
    auditTrailRepository: auditRepo,
    alertService: alertService,
    leakRepository: leakRepo,
    exchangeRepository: exchangeRepo,
    settingsRepository: settingsRepo,
    inventoryAuditRepository: inventoryAuditRepo,
    expenseRepository: expenseRepo,
    sessionRepository: sessionRepo,
    treasuryRepository: treasuryRepo,
    collectionRepository: collectionRepo,
  );
});

final gazStockReportServiceProvider = Provider<GazStockReportService>((ref) {
  final auditRepo = ref.watch(auditTrailRepositoryProvider);
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  return GazStockReportService(
    auditRepository: auditRepo,
    stockRepository: stockRepo,
  );
});

// Realtime Sync Service (nécessite enterpriseId et moduleId)
final realtimeSyncServiceProvider =
    Provider.family<
      RealtimeSyncService,
      ({String enterpriseId, String moduleId})
    >((ref, params) {
      return RealtimeSyncService(
        enterpriseId: params.enterpriseId,
        moduleId: params.moduleId,
      );
    });

// Controllers
final cylinderControllerProvider = Provider<CylinderController>((ref) {
  final repo = ref.watch(gasCylinderRepositoryProvider);
  return CylinderController(repo);
});

final gasControllerProvider = Provider<GasController>((ref) {
  final repo = ref.watch(gasRepositoryProvider);
  final auditService = ref.watch(auditTrailServiceProvider);
  return GasController(repo, auditService);
});

final expenseControllerProvider = Provider<GazExpenseController>((ref) {
  final repo = ref.watch(gazExpenseRepositoryProvider);
  return GazExpenseController(repo);
});

final cylinderStockControllerProvider = Provider<CylinderStockController>((
  ref,
) {
  final repo = ref.watch(cylinderStockRepositoryProvider);
  final service = ref.watch(stockServiceProvider);
  final transactionService = ref.watch(transactionServiceProvider);
  return CylinderStockController(repo, service, transactionService);
});

final cylinderLeakControllerProvider = Provider<CylinderLeakController>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final leakRepo = ref.watch(cylinderLeakRepositoryProvider(enterpriseId));
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  final transactionService = ref.watch(transactionServiceProvider);
  return CylinderLeakController(leakRepo, stockRepo, transactionService);
});

final financialReportControllerProvider = Provider<FinancialReportController>((
  ref,
) {
  final repo = ref.watch(financialReportRepositoryProvider);
  final service = ref.watch(financialCalculationServiceProvider);
  return FinancialReportController(repo, service);
});

final tourControllerProvider = Provider<TourController>((ref) {
  final repo = ref.watch(tourRepositoryProvider);
  final service = ref.watch(tourServiceProvider);
  return TourController(repository: repo, service: service);
});

final wholesalerControllerProvider = Provider<WholesalerController>((ref) {
  final service = ref.watch(wholesalerServiceProvider);
  return WholesalerController(service: service);
});

final leakReportControllerProvider = Provider<LeakReportController>((ref) {
  final service = ref.watch(leakReportServiceProvider);
  return LeakReportController(service: service);
});

final leakReportSummaryProvider =
    FutureProvider.family<Map<int, List<CylinderLeak>>, String>((
      ref,
      enterpriseId,
    ) {
      final controller = ref.watch(leakReportControllerProvider);
      return controller.getPendingLeaksSummary(enterpriseId);
    });

final gazSettingsControllerProvider = Provider<GazSettingsController>((ref) {
  final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
  final enterpriseId = (activeEnterprise?.isPointOfSale == true && activeEnterprise?.type.module == EnterpriseModule.gaz)
      ? (activeEnterprise?.parentEnterpriseId ?? activeEnterprise?.id ?? 'default')
      : (activeEnterprise?.id ?? 'default');
  final repo = ref.watch(gazSettingsRepositoryProvider(enterpriseId));
  return GazSettingsController(repository: repo);
});

final stockTransferControllerProvider = Provider<StockTransferController>((
  ref,
) {
  final repo = ref.watch(stockTransferRepositoryProvider);
  final service = ref.watch(stockTransferServiceProvider);
  return StockTransferController(repo, service);
});

// GazSessionController is defined in its own file

final gazSessionControllerProvider = Provider<GazSessionController>((ref) {
  final sessionRepo = ref.watch(gazSessionRepositoryProvider);
  final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';

  return GazSessionController(
    sessionRepository: sessionRepo,
    enterpriseId: enterpriseId,
  );
});

// Cylinders
final cylindersProvider = StreamProvider.autoDispose<List<Cylinder>>((ref) {
  final controller = ref.watch(cylinderControllerProvider);
  return controller.watchCylinders();
});

/// Provider pour obtenir les types de bouteilles d'un point de vente spécifique (sous-entité de type gasPointOfSale).
final pointOfSaleCylindersProvider =
    StreamProvider.family<
      List<Cylinder>,
      ({String pointOfSaleId, String enterpriseId, String moduleId})
    >((ref, params) {
      final allCylindersAsync = ref.watch(cylindersProvider);

      // Récupérer le point de vente (qui est maintenant une Enterprise)
      final pointsOfSaleAsync = ref.watch(
        enterprisesByParentAndTypeProvider((
          parentId: params.enterpriseId,
          type: EnterpriseType.gasPointOfSale,
        )),
      );

      final allCylinders = allCylindersAsync.value ?? [];
      final pointsOfSale = pointsOfSaleAsync.value ?? [];

      final enterprisePos = pointsOfSale
          .where((pos) => pos.id == params.pointOfSaleId)
          .firstOrNull;

      if (enterprisePos == null) {
        return Stream.value([]);
      }

      final cylinderIds =
          enterprisePos.metadata['cylinderIds'] as List<dynamic>? ?? [];
      final stringCylinderIds = cylinderIds.map((e) => e.toString()).toList();

      // Filtrer les cylinders selon les IDs associés au point de vente
      return Stream.value(
        allCylinders.where((c) => stringCylinderIds.contains(c.id)).toList(),
      );
    });

enum GazDashboardViewType { local, consolidated }

class GazDashboardViewTypeNotifier extends Notifier<GazDashboardViewType> {
  @override
  GazDashboardViewType build() => GazDashboardViewType.consolidated;

  void set(GazDashboardViewType value) => state = value;
}

final gazDashboardViewTypeProvider =
    NotifierProvider<GazDashboardViewTypeNotifier, GazDashboardViewType>(
      GazDashboardViewTypeNotifier.new,
    );

// Sales
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

// Expenses
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

// Stocks
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

/// Données agrégées pour le dashboard gaz.
class GazDashboardData {
  const GazDashboardData({
    required this.sales,
    required this.expenses,
    required this.cylinders,
    required this.stocks,
    required this.transfers,
    required this.pointsOfSale,
  });

  final List<GasSale> sales;
  final List<GazExpense> expenses;
  final List<Cylinder> cylinders;
  final List<CylinderStock> stocks;
  final List<StockTransfer> transfers;
  final List<Enterprise> pointsOfSale;
}

/// Provider combiné pour les données du dashboard gaz.
final gazDashboardDataProviderComplete = StreamProvider<GazDashboardData>((
  ref,
) {
  final salesAsync = ref.watch(gasSalesProvider);
  final expensesAsync = ref.watch(gazExpensesProvider);
  final cylindersAsync = ref.watch(cylindersProvider);
  final stocksAsync = ref.watch(gazStocksProvider);

  final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
  final enterpriseId = activeEnterprise?.id ?? 'default';

  final transfersAsync = ref.watch(stockTransfersProvider(enterpriseId));
  final pointsOfSaleAsync = ref.watch(
    enterprisesByParentAndTypeProvider((
      parentId: enterpriseId,
      type: EnterpriseType.gasPointOfSale,
    )),
  );

  final sales = salesAsync.value ?? [];
  final expenses = expensesAsync.value ?? [];
  final cylinders = cylindersAsync.value ?? [];
  final stocks = stocksAsync.value ?? [];
  final transfers = transfersAsync.value ?? [];
  final pointsOfSale = pointsOfSaleAsync.value ?? [];

  return Stream.value(
    GazDashboardData(
      sales: sales,
      expenses: expenses,
      cylinders: cylinders,
      stocks: stocks,
      transfers: transfers,
      pointsOfSale: pointsOfSale,
    ),
  );
});

// Local-only providers (ignoring viewType)
final gasLocalSalesProvider = StreamProvider<List<GasSale>>((ref) {
  final controller = ref.watch(gasControllerProvider);
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  return controller.watchSales(enterpriseIds: [activeId]);
});

final gazLocalExpensesProvider = StreamProvider<List<GazExpense>>((ref) {
  final controller = ref.watch(expenseControllerProvider);
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  return controller.watchExpenses(enterpriseIds: [activeId]);
});

final gazLocalStocksProvider = StreamProvider<List<CylinderStock>>((ref) {
  final controller = ref.watch(cylinderStockControllerProvider);
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  return controller.watchStocks(activeId, enterpriseIds: [activeId]);
});

/// Version locale du dashboard provider (toujours filtrée par l'entreprise active).
/// Utilisée pour les sections opérationnelles comme la réconciliation de caisse.
final gazLocalDashboardDataProvider =
    StreamProvider<
      ({
        List<GasSale> sales,
        List<GazExpense> expenses,
        List<Cylinder> cylinders,
        List<CylinderStock> stocks,
      })
    >((ref) {
      final salesAsync = ref.watch(gasLocalSalesProvider);
      final expensesAsync = ref.watch(gazLocalExpensesProvider);
      final cylindersAsync = ref.watch(cylindersProvider);
      final stocksAsync = ref.watch(gazLocalStocksProvider);

      final sales = salesAsync.value ?? [];
      final expenses = expensesAsync.value ?? [];
      final cylinders = cylindersAsync.value ?? [];
      final stocks = stocksAsync.value ?? [];

      return Stream.value((
        sales: sales,
        expenses: expenses,
        cylinders: cylinders,
        stocks: stocks,
      ));
    });

// KPIs
final gazTotalSalesProvider = StreamProvider<double>((ref) {
  final salesAsync = ref.watch(gasSalesProvider);
  return Stream.value(
    salesAsync.when(
      data: (sales) => sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    ),
  );
});

final gazTotalExpensesProvider = StreamProvider<double>((ref) {
  final expensesAsync = ref.watch(gazExpensesProvider);
  return Stream.value(
    expensesAsync.when(
      data: (expenses) =>
          expenses.fold<double>(0.0, (sum, e) => sum + e.amount),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    ),
  );
});

final gazProfitProvider = StreamProvider<double>((ref) {
  final totalSalesAsync = ref.watch(gazTotalSalesProvider);
  final totalExpensesAsync = ref.watch(gazTotalExpensesProvider);

  final totalSales = totalSalesAsync.value ?? 0.0;
  final totalExpenses = totalExpensesAsync.value ?? 0.0;

  return Stream.value(totalSales - totalExpenses);
});

// Sessions are managed via GazSessionController
final gazSessionsProvider = StreamProvider<List<GazSession>>((ref) {
  return ref.watch(gazSessionControllerProvider).watchSessions();
});

final activeGazSessionProvider = FutureProvider<GazSession?>((ref) {
  return ref.watch(gazSessionControllerProvider).getActiveSession();
});

final todayGazSessionProvider = FutureProvider<GazSession?>((ref) {
  return ref.watch(gazSessionControllerProvider).getActiveSession();
});

// Report Data Provider
final gazReportDataProvider = FutureProvider.family
    .autoDispose<
      GazReportData,
      ({GazReportPeriod period, DateTime? startDate, DateTime? endDate})
    >((ref, params) async {
      final salesAsync = ref.watch(gasSalesProvider);
      final expensesAsync = ref.watch(gazExpensesProvider);

      final sales = await salesAsync.when(
        data: (data) async => data,
        loading: () async => <GasSale>[],
        error: (_, __) async => <GasSale>[],
      );

      final expenses = await expensesAsync.when(
        data: (data) async => data,
        loading: () async => <GazExpense>[],
        error: (_, __) async => <GazExpense>[],
      );

      // Calculate date range
      DateTime rangeStart;
      DateTime rangeEnd;

      final now = DateTime.now();
      switch (params.period) {
        case GazReportPeriod.today:
          rangeStart = DateTime(now.year, now.month, now.day);
          rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case GazReportPeriod.week:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          rangeStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
          rangeEnd = now;
          break;
        case GazReportPeriod.month:
          rangeStart = DateTime(now.year, now.month, 1);
          rangeEnd = now;
          break;
        case GazReportPeriod.year:
          rangeStart = DateTime(now.year, 1, 1);
          rangeEnd = now;
          break;
        case GazReportPeriod.custom:
          rangeStart = params.startDate ?? DateTime(now.year, now.month, 1);
          rangeEnd = params.endDate ?? now;
          break;
      }

      // Filter sales and expenses by date range
      final filteredSales = sales.where((s) {
        return s.saleDate.isAfter(
              rangeStart.subtract(const Duration(days: 1)),
            ) &&
            s.saleDate.isBefore(rangeEnd.add(const Duration(days: 1)));
      }).toList();

      final filteredExpenses = expenses.where((e) {
        return e.date.isAfter(rangeStart.subtract(const Duration(days: 1))) &&
            e.date.isBefore(rangeEnd.add(const Duration(days: 1)));
      }).toList();

      // Calculate totals
      final salesRevenue = filteredSales.fold<double>(
        0,
        (sum, s) => sum + s.totalAmount,
      );
      final expensesAmount = filteredExpenses.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );
      final profit = salesRevenue - expensesAmount;

      // Count by type
      final retailCount = filteredSales
          .where((s) => s.saleType == SaleType.retail)
          .length;
      final wholesaleCount = filteredSales.length - retailCount;

      // Calculate product breakdown (qty per cylinder label)
      final cylinders = ref.watch(cylindersProvider).value ?? [];
      final Map<String, int> productBreakdown = {};
      for (final sale in filteredSales) {
        final cylinder = cylinders.firstWhere((c) => c.id == sale.cylinderId, 
          orElse: () => const Cylinder(id: '', weight: 0, buyPrice: 0, sellPrice: 0, enterpriseId: '', moduleId: 'gaz'));
        if (cylinder.id.isNotEmpty) {
          final label = cylinder.label;
          productBreakdown[label] = (productBreakdown[label] ?? 0) + sale.quantity;
        }
      }

      // Calculate POS performance if the current enterprise has children
      final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
      List<GazPosPerformance> posPerf = [];
      
      if (activeEnterprise != null && !activeEnterprise.isPointOfSale) {
        final posListAsync = ref.watch(enterprisesByParentAndTypeProvider((
          parentId: activeEnterprise.id,
          type: EnterpriseType.gasPointOfSale,
        )));
        
        final posList = posListAsync.value ?? [];
        if (posList.isNotEmpty) {
          for (final pos in posList) {
            final posSales = filteredSales.where((s) => s.enterpriseId == pos.id).toList();
            if (posSales.isEmpty) continue;

            final posRevenue = posSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
            final posQty = posSales.fold<int>(0, (sum, s) => sum + s.quantity);
            
            // Find top product for this POS
            final Map<String, int> posProdBreakdown = {};
            for (final s in posSales) {
              final cyl = cylinders.firstWhere((c) => c.id == s.cylinderId, 
                orElse: () => const Cylinder(id: '', weight: 0, buyPrice: 0, sellPrice: 0, enterpriseId: '', moduleId: 'gaz'));
              if (cyl.id.isNotEmpty) {
                posProdBreakdown[cyl.label] = (posProdBreakdown[cyl.label] ?? 0) + s.quantity;
              }
            }
            
            String? topProd;
            if (posProdBreakdown.isNotEmpty) {
              topProd = posProdBreakdown.entries
                  .reduce((a, b) => a.value > b.value ? a : b)
                  .key;
            }

            posPerf.add(GazPosPerformance(
              enterpriseName: pos.name,
              revenue: posRevenue,
              salesCount: posSales.length,
              quantitySold: posQty,
              revenuePercentage: salesRevenue > 0 ? (posRevenue / salesRevenue) * 100 : 0,
              topProduct: topProd,
            ));
          }
          // Sort by revenue descending
          posPerf.sort((a, b) => b.revenue.compareTo(a.revenue));
        }
      }

      return GazReportData(
        period: params.period,
        salesRevenue: salesRevenue,
        expensesAmount: expensesAmount,
        profit: profit,
        salesCount: filteredSales.length,
        expensesCount: filteredExpenses.length,
        retailSalesCount: retailCount,
        wholesaleSalesCount: wholesaleCount,
        productBreakdown: productBreakdown,
        posPerformance: posPerf,
      );
    });

// Collections
final gazCollectionsProvider = StreamProvider<List<Collection>>((ref) {
  final repo = ref.watch(collectionRepositoryProvider);
  final viewType = ref.watch(gazDashboardViewTypeProvider);
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';

  if (viewType == GazDashboardViewType.local) {
    return repo.watchCollections(activeId);
  }

  final scopedIds =
      ref.watch(gazScopedEnterpriseIdsProvider).value ?? [activeId];
  return repo.watchCollections(activeId, enterpriseIds: scopedIds);
});

// History filtering for specific enterprise
final collectionsProvider = StreamProvider.family<List<Collection>, String>((
  ref,
  enterpriseId,
) {
  return ref.watch(collectionRepositoryProvider).watchCollections(enterpriseId);
});

// Cylinder Stocks
final cylinderStocksProvider =
    StreamProvider.family<
      List<CylinderStock>,
      ({String enterpriseId, CylinderStatus? status, String? siteId})
    >((ref, params) {
      final controller = ref.watch(cylinderStockControllerProvider);
      return controller.watchStocks(
        params.enterpriseId,
        status: params.status,
        siteId: params.siteId,
      );
    });

// Cylinder Leaks
final cylinderLeaksProvider =
    StreamProvider.family<
      List<CylinderLeak>,
      ({String enterpriseId, LeakStatus? status})
    >((ref, params) {
      final controller = ref.watch(cylinderLeakControllerProvider);
      return controller.watchLeaks(params.enterpriseId, status: params.status);
    });

// Financial Reports
final financialReportsProvider =
    StreamProvider.family<
      List<FinancialReport>,
      ({String enterpriseId, ReportPeriod? period, ReportStatus? status})
    >((ref, params) {
      final controller = ref.watch(financialReportControllerProvider);
      return controller.watchReports(
        params.enterpriseId,
        period: params.period,
        status: params.status,
      );
    });

/// Provider pour calculer les charges pour une période donnée.
final financialChargesProvider =
    FutureProvider.family<
      ({
        double fixedCharges,
        double variableCharges,
        double salaries,
        double loadingEventExpenses,
        double totalExpenses,
      }),
      ({String enterpriseId, DateTime startDate, DateTime endDate})
    >((ref, params) async {
      final service = ref.watch(financialCalculationServiceProvider);
      return service.calculateCharges(
        params.enterpriseId,
        params.startDate,
        params.endDate,
      );
    });

/// Provider pour l'historique des mouvements de stock.
final gazStockHistoryProvider =
    FutureProvider.family<
      List<StockMovement>,
      ({
        String enterpriseId,
        DateTime startDate,
        DateTime endDate,
        String? siteId,
      })
    >((ref, params) async {
      final service = ref.watch(gazStockReportServiceProvider);
      final viewType = ref.watch(gazDashboardViewTypeProvider);

      List<String> enterpriseIds;
      if (viewType == GazDashboardViewType.local) {
        enterpriseIds = [params.enterpriseId];
      } else {
        enterpriseIds =
            ref.watch(gazScopedEnterpriseIdsProvider).value ??
            [params.enterpriseId];
      }

      return service.getStockHistory(
        enterpriseIds: enterpriseIds,
        startDate: params.startDate,
        endDate: params.endDate,
        siteId: params.siteId,
      );
    });

/// Provider pour le résumé du stock actuel.
final gazStockSummaryProvider =
    FutureProvider.family<
      Map<int, Map<CylinderStatus, int>>,
      ({String enterpriseId, String? siteId})
    >((ref, params) async {
      final service = ref.watch(gazStockReportServiceProvider);
      final viewType = ref.watch(gazDashboardViewTypeProvider);

      List<String> enterpriseIds;
      if (viewType == GazDashboardViewType.local) {
        enterpriseIds = [params.enterpriseId];
      } else {
        enterpriseIds =
            ref.watch(gazScopedEnterpriseIdsProvider).value ??
            [params.enterpriseId];
      }

      return service.getStockSummary(
        enterpriseIds: enterpriseIds,
        siteId: params.siteId,
      );
    });

/// Provider pour calculer le reliquat net pour une période donnée.
final financialNetAmountProvider =
    FutureProvider.family<
      double,
      ({
        String enterpriseId,
        DateTime startDate,
        DateTime endDate,
        double totalRevenue,
      })
    >((ref, params) async {
      final controller = ref.watch(financialReportControllerProvider);
      return controller.calculateNetAmount(
        params.enterpriseId,
        params.startDate,
        params.endDate,
        params.totalRevenue,
      );
    });

/// Provider pour récupérer tous les grossistes.
final allWholesalersProvider = StreamProvider.family<List<Wholesaler>, String>((
  ref,
  enterpriseId,
) {
  final service = ref.watch(wholesalerServiceProvider);
  return Stream.fromFuture(service.getAllWholesalers(enterpriseId));
});

/// Provider pour récupérer un tour spécifique par son ID.
final tourProvider = StreamProvider.autoDispose.family<Tour?, String>((
  ref,
  tourId,
) {
  final controller = ref.watch(tourControllerProvider);
  // tourProvider ne devrait généralement pas avoir besoin de watch ici,
  // mais pour la cohérence et au cas où le tour est mis à jour localement:
  final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';
  return controller
      .watchTours(enterpriseId)
      .map((tours) => tours.where((t) => t.id == tourId).firstOrNull);
});

// Tours
final toursProvider =
    StreamProvider.family<
      List<Tour>,
      ({String enterpriseId, TourStatus? status})
    >((ref, params) {
      final controller = ref.watch(tourControllerProvider);
      return controller.watchTours(params.enterpriseId, status: params.status);
    });

// Gaz Settings
final gazSettingsProvider =
    StreamProvider.family<
      GazSettings?,
      ({String enterpriseId, String moduleId})
    >((ref, params) {
      final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
      final effectiveEnterpriseId = activeEnterprise != null &&
              activeEnterprise.isPointOfSale &&
              activeEnterprise.type.module == EnterpriseModule.gaz &&
              activeEnterprise.id == params.enterpriseId
          ? (activeEnterprise.parentEnterpriseId ?? params.enterpriseId)
          : params.enterpriseId;
      final controller = ref.watch(gazSettingsControllerProvider);
      return controller.watchSettings(
        enterpriseId: effectiveEnterpriseId,
        moduleId: params.moduleId,
      );
    });

// Stock Transfers
final stockTransfersProvider =
    StreamProvider.family<List<StockTransfer>, String>((ref, enterpriseId) {
      final controller = ref.watch(stockTransferControllerProvider);
      return controller.watchTransfers(enterpriseId);
    });
// Stock Alerts
final lowStockAlertsProvider = FutureProvider.family<List<StockAlert>, String>((
  ref,
  enterpriseId,
) async {
  final alertService = ref.watch(gasAlertServiceProvider);
  final cylindersAsync = ref.watch(cylindersProvider);

  return cylindersAsync.when(
    data: (cylinders) async {
      final alerts = <StockAlert>[];
      for (final cylinder in cylinders) {
        final alert = await alertService.checkStockLevel(
          enterpriseId: enterpriseId,
          cylinderId: cylinder.id,
          weight: cylinder.weight,
          status: CylinderStatus.full,
        );
        if (alert != null) {
          alerts.add(alert);
        }
      }
      return alerts;
    },
    loading: () => <StockAlert>[],
    error: (_, __) => <StockAlert>[],
  );
});

/// Ventes du dépôt principal uniquement (exclut les POS).
/// Utilisé pour calculer les recettes brutes dans la synthèse trésorerie.
final gazHqSalesProvider = StreamProvider<List<GasSale>>((ref) {
  final controller = ref.watch(gasControllerProvider);
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  // Only the main enterprise's own sales
  return controller.watchSales(enterpriseIds: [activeId]);
});

/// Tours clôturés du dépôt principal.
/// Utilisé pour calculer les dépenses de tournées dans la synthèse trésorerie.
final gazClosedToursProvider = StreamProvider<List<Tour>>((ref) {
  final activeId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  final controller = ref.watch(tourControllerProvider);
  return controller.watchTours(activeId, status: TourStatus.closed);
});

