import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/tenant/tenant_provider.dart';

import '../../domain/services/credit_calculation_service.dart';
import '../../domain/services/credit_service.dart';
import '../../domain/services/dashboard_calculation_service.dart';
import '../../domain/services/electricity_meter_config_service.dart';
import '../../domain/services/machine_stock_management_service.dart';
import '../../domain/services/production_payment_calculation_service.dart';
import '../../domain/services/production_payment_validation_service.dart';
import '../../domain/services/production_period_service.dart';
import '../../domain/services/production_service.dart';
import '../../domain/services/profitability_calculation_service.dart';
import '../../domain/services/report_calculation_service.dart';
import '../../domain/services/payment_splitter_service.dart';
import '../../domain/services/production_session_builder.dart';
import '../../domain/services/production_session_status_calculator.dart';
import '../../domain/services/salary_calculation_service.dart';
import '../../domain/services/sale_calculation_service.dart';
import '../../domain/services/sale_service.dart';
import '../../domain/services/validation/production_validation_service.dart';
import '../../domain/services/stock_integrity_service.dart';
import '../../domain/services/treasury_movement_mapper.dart';
import '../../domain/services/historical_stock_service.dart';
import '../../domain/services/machine_material_cost_service.dart';
import '../../domain/services/stock_history_service.dart';
import '../../domain/services/stock_reconciliation_service.dart';
import 'controller_providers.dart';
import 'repository_providers.dart';

// Service Providers
final saleServiceProvider = Provider<SaleService>((ref) {
  return SaleService(
    stockRepository: ref.watch(stockRepositoryProvider),
    customerRepository: ref.watch(customerRepositoryProvider),
    productRepository: ref.watch(eauMineraleProductRepositoryProvider),
  );
});

/// Provider for SaleCalculationService.
final saleCalculationServiceProvider = Provider<SaleCalculationService>(
  (ref) => SaleCalculationService(),
);

final creditServiceProvider = Provider<CreditService>((ref) {
  final creditRepo = ref.watch(creditRepositoryProvider);
  final saleRepo = ref.watch(saleRepositoryProvider);
  final treasuryRepo = ref.watch(treasuryRepositoryProvider);

  return CreditService(
    creditRepository: creditRepo,
    saleRepository: saleRepo,
    treasuryRepository: treasuryRepo,
  );
});

final dashboardCalculationServiceProvider =
    Provider<DashboardCalculationService>(
      (ref) => DashboardCalculationService(),
    );

/// Provider for ProductionValidationService.
final productionValidationServiceProvider =
    Provider<ProductionValidationService>(
      (ref) => ProductionValidationService(),
    );

/// Provider alias for product validation (uses ProductionValidationService).
/// This is used by product form widgets for validation.
final productValidationServiceProvider = Provider<ProductionValidationService>(
  (ref) => ProductionValidationService(),
);

final productionPaymentCalculationServiceProvider =
    Provider<ProductionPaymentCalculationService>(
      (ref) => ProductionPaymentCalculationService(),
    );

/// Provider for ProductionPaymentValidationService.
final productionPaymentValidationServiceProvider =
    Provider<ProductionPaymentValidationService>(
      (ref) => ProductionPaymentValidationService(),
    );

final reportCalculationServiceProvider = Provider<ReportCalculationService>(
  (ref) => ReportCalculationService(),
);

final productionServiceProvider = Provider<ProductionService>(
  (ref) => ProductionService(),
);

final profitabilityCalculationServiceProvider =
    Provider<ProfitabilityCalculationService>(
      (ref) => ProfitabilityCalculationService(),
    );

final productionPeriodServiceProvider = Provider<ProductionPeriodService>(
  (ref) => ProductionPeriodService(),
);

final electricityMeterConfigServiceProvider =
    Provider<ElectricityMeterConfigService>(
      (ref) => ElectricityMeterConfigService.instance,
    );

/// Provider for PaymentSplitterService.
final paymentSplitterServiceProvider = Provider<PaymentSplitterService>(
  (ref) => PaymentSplitterService(),
);

/// Provider for ProductionSessionBuilder.
final productionSessionBuilderProvider = Provider<ProductionSessionBuilder>(
  (ref) => ProductionSessionBuilder(),
);

/// Provider for ProductionSessionStatusCalculator.
final productionSessionStatusCalculatorProvider =
    Provider<ProductionSessionStatusCalculator>(
      (ref) => ProductionSessionStatusCalculator(),
    );

/// Provider for CreditCalculationService.
final creditCalculationServiceProvider = Provider<CreditCalculationService>(
  (ref) => CreditCalculationService(),
);

/// Provider for SalaryCalculationService.
final salaryCalculationServiceProvider = Provider<SalaryCalculationService>(
  (ref) => SalaryCalculationService(),
);

/// Provider for StockIntegrityService.
final stockIntegrityServiceProvider = Provider<StockIntegrityService>((ref) {
  return StockIntegrityService(
    stockRepository: ref.watch(stockRepositoryProvider),
    productRepository: ref.watch(eauMineraleProductRepositoryProvider),
  );
});

/// Provider for HistoricalStockService
final historicalStockServiceProvider = Provider<HistoricalStockService>((ref) {
  final stockController = ref.read(stockControllerProvider);
  final stockHistoryService = ref.watch(stockHistoryServiceProvider);
  return HistoricalStockService(stockController, stockHistoryService);
});

/// Provider for MachineMaterialCostService
final machineMaterialCostServiceProvider = Provider<MachineMaterialCostService>((ref) {
  return MachineMaterialCostService(
    sessionRepository: ref.watch(productionSessionRepositoryProvider),
    productRepository: ref.watch(eauMineraleProductRepositoryProvider),
  );
});

/// Provider for MachineStockManagementService
final machineStockManagementServiceProvider = Provider<MachineStockManagementService>((ref) {
  return MachineStockManagementService(
    sessionRepository: ref.watch(productionSessionRepositoryProvider),
    stockRepository: ref.watch(stockRepositoryProvider),
    stockController: ref.read(stockControllerProvider),
  );
});

/// Provider for TreasuryMovementMapper.
final treasuryMovementMapperProvider = Provider<TreasuryMovementMapper>(
  (ref) => const TreasuryMovementMapper(),
);

/// Provider for StockHistoryService
final stockHistoryServiceProvider = Provider<StockHistoryService>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
  return StockHistoryService(
    ref.watch(stockRepositoryProvider),
    enterpriseId,
  );
});

/// Provider for StockReconciliationService
final stockReconciliationServiceProvider = Provider<StockReconciliationService>((ref) {
  return StockReconciliationService(
    ref.watch(stockRepositoryProvider),
  );
});
