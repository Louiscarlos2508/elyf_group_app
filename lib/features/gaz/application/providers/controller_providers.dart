import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../../audit_trail/application/providers.dart';

import '../controllers/cylinder_controller.dart';
import '../controllers/cylinder_leak_controller.dart';
import '../controllers/cylinder_stock_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/financial_report_controller.dart';
import '../controllers/gas_controller.dart';
import '../controllers/gaz_settings_controller.dart';
import '../controllers/wholesaler_controller.dart';
import '../controllers/gaz_employee_controller.dart';
import '../controllers/gaz_salary_payment_controller.dart';
import '../controllers/leak_report_controller.dart';

import 'repository_providers.dart';
import 'service_providers.dart';

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

final cylinderStockControllerProvider = Provider<CylinderStockController>((ref) {
  final repo = ref.watch(cylinderStockRepositoryProvider);
  final service = ref.watch(stockServiceProvider);
  final transactionService = ref.watch(transactionServiceProvider);
  return CylinderStockController(repo, service, transactionService);
});

final cylinderLeakControllerProvider = Provider<CylinderLeakController>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final leakRepo = ref.watch(cylinderLeakRepositoryProvider(enterpriseId));
  final stockRepo = ref.watch(cylinderStockRepositoryProvider);
  final transactionService = ref.watch(transactionServiceProvider);
  return CylinderLeakController(leakRepo, stockRepo, transactionService);
});

final financialReportControllerProvider = Provider<FinancialReportController>((ref) {
  final repo = ref.watch(financialReportRepositoryProvider);
  final service = ref.watch(financialCalculationServiceProvider);
  return FinancialReportController(repo, service);
});

final wholesalerControllerProvider = Provider<WholesalerController>((ref) {
  final service = ref.watch(wholesalerServiceProvider);
  return WholesalerController(service: service);
});

final leakReportControllerProvider = Provider<LeakReportController>((ref) {
  final service = ref.watch(leakReportServiceProvider);
  return LeakReportController(service: service);
});

final gazSettingsControllerProvider = Provider.family<GazSettingsController, String>((ref, enterpriseId) {
  final repo = ref.watch(gazSettingsRepositoryProvider(enterpriseId));
  return GazSettingsController(repository: repo);
});

final gazEmployeeControllerProvider = Provider<GazEmployeeController>((ref) {
  final repository = ref.watch(gazEmployeeRepositoryProvider);
  return GazEmployeeController(repository: repository);
});

final gazSalaryPaymentControllerProvider = Provider<GazSalaryPaymentController>((ref) {
  final repository = ref.watch(gazSalaryPaymentRepositoryProvider);
  final treasuryRepository = ref.watch(gazTreasuryRepositoryProvider);
  return GazSalaryPaymentController(
    repository: repository,
    treasuryRepository: treasuryRepository,
  );
});
