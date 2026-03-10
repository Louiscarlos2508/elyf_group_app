import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

import '../../data/repositories/cylinder_leak_offline_repository.dart';
import '../../data/repositories/cylinder_stock_offline_repository.dart';
import '../../data/repositories/expense_offline_repository.dart';
import '../../data/repositories/financial_report_offline_repository.dart';
import '../../data/repositories/gas_offline_repository.dart';
import '../../data/repositories/exchange_offline_repository.dart';
import '../../data/repositories/gaz_settings_offline_repository.dart';
import '../../data/repositories/tour_offline_repository.dart';
import '../../data/repositories/wholesaler_offline_repository.dart';
import '../../data/repositories/treasury_offline_repository.dart';
import '../../data/repositories/gaz_employee_offline_repository.dart';
import '../../data/repositories/gaz_salary_payment_offline_repository.dart';
import '../../data/repositories/pos_remittance_offline_repository.dart';
import '../../data/repositories/site_logistics_record_offline_repository.dart';
import '../../data/repositories/inventory_audit_offline_repository.dart';

import '../../domain/repositories/cylinder_leak_repository.dart';
import '../../domain/repositories/cylinder_stock_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/financial_report_repository.dart';
import '../../domain/repositories/gas_repository.dart';
import '../../domain/repositories/exchange_repository.dart';
import '../../domain/repositories/gaz_settings_repository.dart';
import '../../domain/repositories/tour_repository.dart';
import '../../domain/repositories/wholesaler_repository.dart';
import '../../domain/repositories/treasury_repository.dart';
import '../../domain/repositories/gaz_employee_repository.dart';
import '../../domain/repositories/gaz_salary_payment_repository.dart';
import '../../domain/repositories/pos_remittance_repository.dart';
import '../../domain/repositories/site_logistics_record_repository.dart';
import '../../domain/repositories/inventory_audit_repository.dart';

final gasRepositoryProvider = Provider<GasRepository>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
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
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
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
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
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

final cylinderStockRepositoryProvider = Provider<CylinderStockRepository>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
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

final cylinderLeakRepositoryProvider = Provider.family<CylinderLeakRepository, String>((ref, enterpriseId) {
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

final exchangeRepositoryProvider = Provider.family<ExchangeRepository, String>((ref, enterpriseId) {
  final drift = ref.watch(driftServiceProvider);
  final sync = ref.watch(syncManagerProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  return ExchangeOfflineRepository(
    driftService: drift,
    syncManager: sync,
    connectivityService: connectivity,
    enterpriseId: enterpriseId,
  );
});

final tourRepositoryProvider = Provider<TourRepository>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
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
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
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

final gazSettingsRepositoryProvider = Provider.family<GazSettingsRepository, String>((ref, enterpriseId) {
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

final financialReportRepositoryProvider = Provider<FinancialReportRepository>((ref) {
  final enterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? 'default';
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

final inventoryAuditRepositoryProvider = Provider.family<GazInventoryAuditRepository, String>((ref, enterpriseId) {
  return GazInventoryAuditOfflineRepository(
    driftService: ref.watch(driftServiceProvider),
    syncManager: ref.watch(syncManagerProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    enterpriseId: enterpriseId,
  );
});

final gazPOSRemittanceRepositoryProvider = Provider<GazPOSRemittanceRepository>((ref) {
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final activeEnterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? '';

  return GazPOSRemittanceOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivity,
    enterpriseId: activeEnterpriseId,
    moduleType: 'gaz',
  );
});

final siteLogisticsRecordRepositoryProvider = Provider<GazSiteLogisticsRecordRepository>((ref) {
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final activeEnterpriseId = ref.watch(activeEnterpriseIdProvider).value ?? '';

  return GazSiteLogisticsRecordOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivity,
    enterpriseId: activeEnterpriseId,
    moduleType: 'gaz',
  );
});

final gazEmployeeRepositoryProvider = Provider<GazEmployeeRepository>((ref) {
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  return GazEmployeeOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
  );
});

final gazSalaryPaymentRepositoryProvider = Provider<GazSalaryPaymentRepository>((ref) {
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  return GazSalaryPaymentOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
  );
});
