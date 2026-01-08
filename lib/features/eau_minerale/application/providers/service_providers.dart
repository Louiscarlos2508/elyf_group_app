import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/credit_service.dart';
import '../../domain/services/dashboard_calculation_service.dart';
import '../../domain/services/electricity_meter_config_service.dart';
import '../../domain/services/production_payment_calculation_service.dart';
import '../../domain/services/production_period_service.dart';
import '../../domain/services/production_service.dart';
import '../../domain/services/profitability_calculation_service.dart';
import '../../domain/services/report_calculation_service.dart';
import '../../domain/services/sale_service.dart';
import '../../domain/services/validation/production_validation_service.dart';
import 'repository_providers.dart';

// Service Providers
final saleServiceProvider = Provider<SaleService>(
  (ref) {
    final stockRepo = ref.watch(stockRepositoryProvider);
    final customerRepo = ref.watch(customerRepositoryProvider);
    
    return SaleService(
      stockRepository: stockRepo,
      customerRepository: customerRepo,
    );
  },
);

final creditServiceProvider = Provider<CreditService>(
  (ref) {
    final creditRepo = ref.watch(creditRepositoryProvider);
    final saleRepo = ref.watch(saleRepositoryProvider);
    
    return CreditService(
      creditRepository: creditRepo,
      saleRepository: saleRepo,
    );
  },
);

final dashboardCalculationServiceProvider = Provider<DashboardCalculationService>(
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

