import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/credit_calculation_service.dart';
import '../../domain/services/credit_service.dart';
import '../../domain/services/dashboard_calculation_service.dart';
import '../../domain/services/electricity_meter_config_service.dart';
import '../../domain/services/production_payment_calculation_service.dart';
import '../../domain/services/production_payment_validation_service.dart';
import '../../domain/services/production_period_service.dart';
import '../../domain/services/production_service.dart';
import '../../domain/services/profitability_calculation_service.dart';
import '../../domain/services/report_calculation_service.dart';
import '../../domain/services/payment_splitter_service.dart';
import '../../domain/services/production_session_builder.dart';
import '../../domain/services/production_session_status_calculator.dart';
import '../../domain/services/production_session_validation_service.dart';
import '../../domain/services/salary_calculation_service.dart';
import '../../domain/services/sale_calculation_service.dart';
import '../../domain/services/sale_service.dart';
import '../../domain/services/validation/production_validation_service.dart';
import '../../domain/services/stock_integrity_service.dart';
import 'controller_providers.dart';
import 'repository_providers.dart';

// Service Providers
final saleServiceProvider = Provider<SaleService>((ref) {
  return SaleService(
    stockRepository: ref.watch(stockRepositoryProvider),
    customerRepository: ref.watch(customerRepositoryProvider),
    packStockAdapter: ref.watch(packStockAdapterProvider),
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

  return CreditService(creditRepository: creditRepo, saleRepository: saleRepo);
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

/// Provider for ProductionSessionValidationService.
final productionSessionValidationServiceProvider =
    Provider<ProductionSessionValidationService>(
      (ref) => ProductionSessionValidationService(),
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
  final bobineRepo = ref.watch(bobineStockQuantityRepositoryProvider);
  final packagingRepo = ref.watch(packagingStockRepositoryProvider);

  return StockIntegrityService(
    bobineRepository: bobineRepo,
    packagingRepository: packagingRepo,
  );
});
