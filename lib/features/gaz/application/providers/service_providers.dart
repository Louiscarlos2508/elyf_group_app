import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/printing/printer_provider.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import '../../../audit_trail/application/providers.dart';

import '../../domain/services/gaz_dashboard_calculation_service.dart';
import '../../domain/services/gaz_report_calculation_service.dart';
import '../../domain/services/filtering/gaz_filter_service.dart';
import '../../domain/services/gas_alert_service.dart';
import '../../domain/services/gas_validation_service.dart';
import '../../domain/services/wholesaler_service.dart';
import '../../domain/services/leak_report_service.dart';
import '../../domain/services/gaz_printing_service.dart';
import '../../domain/services/financial_calculation_service.dart';
import '../../domain/services/stock_service.dart';
import '../../domain/services/tour_service.dart';
import '../../domain/services/data_consistency_service.dart';
import '../../domain/services/gaz_stock_report_service.dart';
import '../../domain/services/realtime_sync_service.dart';
import '../../domain/services/transaction_service.dart';
import '../../domain/services/gaz_reconciliation_service.dart';

import 'repository_providers.dart';

// Service Providers
final gazDashboardCalculationServiceProvider = Provider<GazDashboardCalculationService>((ref) => GazDashboardCalculationService());
final gazReportCalculationServiceProvider = Provider<GazReportCalculationService>((ref) => GazReportCalculationService());
final gazFilterServiceProvider = Provider<GazFilterService>((ref) => GazFilterService());

final gasAlertServiceProvider = Provider<GasAlertService>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final settingsRepo = ref.watch(gazSettingsRepositoryProvider(enterpriseId));
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  return GasAlertService(
    settingsRepository: settingsRepo,
    stockRepository: stockRepo,
  );
});

final gasValidationServiceProvider = Provider<GasValidationService>((ref) => GasValidationService());

final wholesalerServiceProvider = Provider<WholesalerService>((ref) {
  final gasRepository = ref.watch(gasRepositoryProvider);
  final wholesalerRepository = ref.watch(wholesalerRepositoryProvider);
  return WholesalerService(
    gasRepository: gasRepository,
    wholesalerRepository: wholesalerRepository,
  );
});

final leakReportServiceProvider = Provider<LeakReportService>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final leakRepository = ref.watch(cylinderLeakRepositoryProvider(enterpriseId));
  return LeakReportService(leakRepository: leakRepository);
});

final gazPrintingServiceProvider = Provider<GazPrintingService>((ref) {
  final printerService = ref.watch(activePrinterProvider);
  return GazPrintingService(printerService: printerService);
});

final financialCalculationServiceProvider = Provider<FinancialCalculationService>((ref) {
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

final dataConsistencyServiceProvider = Provider<DataConsistencyService>((ref) {
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  final gasRepo = ref.watch(gasCylinderRepositoryProvider);
  final tourRepo = ref.watch(tourRepositoryProvider);
  return DataConsistencyService(
    stockRepository: stockRepo,
    gasRepository: gasRepo,
    tourRepository: tourRepo,
  );
});

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  final gasRepo = ref.watch(gasCylinderRepositoryProvider);
  final tourRepo = ref.watch(tourRepositoryProvider);
  final consistencyService = ref.watch(dataConsistencyServiceProvider);
  final auditRepo = ref.watch(auditTrailRepositoryProvider);
  final alertService = ref.watch(gasAlertServiceProvider);
  final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final leakRepo = ref.watch(cylinderLeakRepositoryProvider(enterpriseId));
  final exchangeRepo = ref.watch(exchangeRepositoryProvider(enterpriseId));
  final settingsRepo = ref.watch(gazSettingsRepositoryProvider(enterpriseId));
  final inventoryAuditRepo = ref.watch(inventoryAuditRepositoryProvider(enterpriseId));
  final expenseRepo = ref.watch(gazExpenseRepositoryProvider);
  final treasuryRepo = ref.watch(gazTreasuryRepositoryProvider);

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
    treasuryRepository: treasuryRepo,
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

final realtimeSyncServiceProvider = Provider.family<RealtimeSyncService, ({String enterpriseId, String moduleId})>((ref, params) {
  return RealtimeSyncService(
    enterpriseId: params.enterpriseId,
    moduleId: params.moduleId,
  );
});

final gazReconciliationServiceProvider = Provider<GazReconciliationService>((ref) {
  final activeEnterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? '';
  return GazReconciliationService(
    tourRepository: ref.watch(tourRepositoryProvider),
    remittanceRepository: ref.watch(gazPOSRemittanceRepositoryProvider),
    leakRepository: ref.watch(cylinderLeakRepositoryProvider(activeEnterpriseId)),
    settingsRepository: ref.watch(gazSettingsRepositoryProvider(activeEnterpriseId)),
    enterpriseRepository: ref.watch(enterpriseRepositoryProvider),
    gasRepository: ref.watch(gasRepositoryProvider),
  );
});
