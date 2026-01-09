import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../data/repositories/contract_offline_repository.dart';
import '../data/repositories/property_expense_offline_repository.dart';
import '../data/repositories/payment_offline_repository.dart';
import '../data/repositories/property_offline_repository.dart';
import '../data/repositories/tenant_offline_repository.dart';
import '../domain/entities/contract.dart';
import '../domain/adapters/expense_balance_adapter.dart';
import '../domain/entities/expense.dart';
import '../domain/entities/payment.dart';
import '../../../../core/domain/entities/expense_balance_data.dart';
import '../domain/entities/property.dart';
import '../domain/entities/tenant.dart';
import '../domain/repositories/contract_repository.dart';
import '../domain/repositories/expense_repository.dart';
import '../domain/repositories/payment_repository.dart';
import '../domain/repositories/property_repository.dart';
import '../domain/repositories/tenant_repository.dart';
import 'controllers/contract_controller.dart';
import 'controllers/expense_controller.dart';
import 'controllers/payment_controller.dart';
import 'controllers/property_controller.dart';
import 'controllers/tenant_controller.dart';
import '../domain/services/calculation/immobilier_report_calculation_service.dart';
import '../domain/services/dashboard_calculation_service.dart';
import '../domain/services/filtering/expense_filter_service.dart';
import '../domain/services/filtering/payment_filter_service.dart';
import '../domain/services/immobilier_validation_service.dart';
import '../domain/services/property_calculation_service.dart';
import '../domain/services/property_validation_service.dart';
import '../domain/services/validation/contract_validation_service.dart';

// Report Calculation Service
final immobilierReportCalculationServiceProvider = Provider<ImmobilierReportCalculationService>(
  (ref) => ImmobilierReportCalculationService(),
);

// Repositories
final propertyRepositoryProvider = Provider<PropertyRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return PropertyOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
    );
  },
);

final tenantRepositoryProvider = Provider<TenantRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return TenantOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
    );
  },
);

final contractRepositoryProvider = Provider<ContractRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return ContractOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
    );
  },
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return PaymentOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
    );
  },
);

final expenseRepositoryProvider = Provider<PropertyExpenseRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return PropertyExpenseOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
    );
  },
);

// Validation Service
final immobilierValidationServiceProvider = Provider<ImmobilierValidationService>(
  (ref) => ImmobilierValidationService(
    ref.watch(propertyRepositoryProvider),
    ref.watch(contractRepositoryProvider),
    ref.watch(paymentRepositoryProvider),
  ),
);

final contractValidationServiceProvider = Provider<ContractValidationService>(
  (ref) => ContractValidationService(),
);

/// Provider for PropertyCalculationService.
final propertyCalculationServiceProvider = Provider<PropertyCalculationService>(
  (ref) => PropertyCalculationService(),
);

/// Provider for PropertyValidationService.
final propertyValidationServiceProvider = Provider<PropertyValidationService>(
  (ref) => PropertyValidationService(),
);

// Dashboard Calculation Service
final immobilierDashboardCalculationServiceProvider =
    Provider<ImmobilierDashboardCalculationService>(
  (ref) => ImmobilierDashboardCalculationService(),
);

// Controllers
final propertyControllerProvider = Provider<PropertyController>(
  (ref) => PropertyController(
    ref.watch(propertyRepositoryProvider),
    ref.watch(immobilierValidationServiceProvider),
  ),
);

final tenantControllerProvider = Provider<TenantController>(
  (ref) => TenantController(
    ref.watch(tenantRepositoryProvider),
    ref.watch(immobilierValidationServiceProvider),
  ),
);

final contractControllerProvider = Provider<ContractController>(
  (ref) => ContractController(
    ref.watch(contractRepositoryProvider),
    ref.watch(propertyRepositoryProvider),
    ref.watch(immobilierValidationServiceProvider),
  ),
);

final paymentControllerProvider = Provider<PaymentController>(
  (ref) => PaymentController(
    ref.watch(paymentRepositoryProvider),
    ref.watch(immobilierValidationServiceProvider),
  ),
);

final expenseControllerProvider = Provider<PropertyExpenseController>(
  (ref) => PropertyExpenseController(ref.watch(expenseRepositoryProvider)),
);

// Data Providers
final propertiesProvider = FutureProvider.autoDispose<List<Property>>(
  (ref) async {
    final controller = ref.watch(propertyControllerProvider);
    return await controller.fetchProperties();
  },
);

final tenantsProvider = FutureProvider.autoDispose<List<Tenant>>(
  (ref) async {
    final controller = ref.watch(tenantControllerProvider);
    return await controller.fetchTenants();
  },
);

final contractsProvider = FutureProvider.autoDispose<List<Contract>>(
  (ref) async {
    final controller = ref.watch(contractControllerProvider);
    return await controller.fetchContracts();
  },
);

final paymentsProvider = FutureProvider.autoDispose<List<Payment>>(
  (ref) async {
    final controller = ref.watch(paymentControllerProvider);
    return await controller.fetchPayments();
  },
);

final expensesProvider = FutureProvider.autoDispose<List<PropertyExpense>>(
  (ref) async {
    final controller = ref.watch(expenseControllerProvider);
    return await controller.fetchExpenses();
  },
);

/// Provider pour le bilan des dépenses Immobilier.
final immobilierExpenseBalanceProvider =
    FutureProvider.autoDispose<List<ExpenseBalanceData>>(
  (ref) async {
    final expenses = await ref.watch(expenseControllerProvider).fetchExpenses();
    final adapter = ImmobilierExpenseBalanceAdapter();
    return adapter.convertToBalanceData(expenses);
  },
);

/// Provider pour les contrats d'un locataire spécifique.
final contractsByTenantProvider =
    FutureProvider.autoDispose.family<List<Contract>, String>(
  (ref, tenantId) async {
    final repository = ref.watch(contractRepositoryProvider);
    return await repository.getContractsByTenant(tenantId);
  },
);

/// Provider pour les paiements d'un contrat spécifique.
final paymentsByContractProvider =
    FutureProvider.autoDispose.family<List<Payment>, String>(
  (ref, contractId) async {
    final repository = ref.watch(paymentRepositoryProvider);
    return await repository.getPaymentsByContract(contractId);
  },
);

/// Provider pour les contrats d'une propriété spécifique.
final contractsByPropertyProvider =
    FutureProvider.autoDispose.family<List<Contract>, String>(
  (ref, propertyId) async {
    final repository = ref.watch(contractRepositoryProvider);
    return await repository.getContractsByProperty(propertyId);
  },
);

/// Provider pour tous les paiements d'un locataire (via ses contrats).
final paymentsByTenantProvider =
    FutureProvider.autoDispose.family<List<Payment>, String>(
  (ref, tenantId) async {
    final contracts = await ref.watch(contractsByTenantProvider((tenantId)).future);
    final paymentRepository = ref.watch(paymentRepositoryProvider);
    final allPayments = <Payment>[];
    for (final contract in contracts) {
      final payments = await paymentRepository.getPaymentsByContract(contract.id);
      allPayments.addAll(payments);
    }
    // Trier par date décroissante
    allPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return allPayments;
  },
);

// Filter Services
final paymentFilterServiceProvider = Provider<PaymentFilterService>(
  (ref) => PaymentFilterService(),
);

final expenseFilterServiceProvider = Provider<ExpenseFilterService>(
  (ref) => ExpenseFilterService(),
);

