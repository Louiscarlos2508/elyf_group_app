import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

export 'providers/permission_providers.dart';
export 'providers/section_providers.dart';

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
final immobilierReportCalculationServiceProvider =
    Provider<ImmobilierReportCalculationService>(
      (ref) => ImmobilierReportCalculationService(),
    );

// Repositories
final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return PropertyOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
  );
});

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return TenantOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
  );
});

final contractRepositoryProvider = Provider<ContractRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return ContractOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
  );
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return PaymentOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
  );
});

final expenseRepositoryProvider = Provider<PropertyExpenseRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(syncManagerProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  return PropertyExpenseOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
  );
});

// Validation Service
final immobilierValidationServiceProvider =
    Provider<ImmobilierValidationService>(
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

/// Provider combiné pour les métriques mensuelles du dashboard immobilier.
final immobilierMonthlyMetricsProvider = StreamProvider.autoDispose<
    ({
      List<Property> properties,
      List<Tenant> tenants,
      List<Contract> contracts,
      List<Payment> payments,
      List<PropertyExpense> expenses,
    })>(
  (ref) {
    return CombineLatestStream.combine5(
      ref.watch(propertiesProvider.stream),
      ref.watch(tenantsProvider.stream),
      ref.watch(contractsProvider.stream),
      ref.watch(paymentsProvider.stream),
      ref.watch(expensesProvider.stream),
      (properties, tenants, contracts, payments, expenses) => (
        properties: properties,
        tenants: tenants,
        contracts: contracts,
        payments: payments,
        expenses: expenses,
      ),
    );
  },
);

/// Provider combiné pour les alertes du dashboard immobilier.
final immobilierAlertsProvider = StreamProvider.autoDispose<
    ({List<Payment> payments, List<Contract> contracts})>(
  (ref) {
    return CombineLatestStream.combine2(
      ref.watch(paymentsProvider.stream),
      ref.watch(contractsProvider.stream),
      (payments, contracts) => (
        payments: payments,
        contracts: contracts,
      ),
    );
  },
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
final propertiesProvider = StreamProvider.autoDispose<List<Property>>((ref) {
  final controller = ref.watch(propertyControllerProvider);
  return controller.watchProperties();
});

final tenantsProvider = StreamProvider.autoDispose<List<Tenant>>((ref) {
  final controller = ref.watch(tenantControllerProvider);
  return controller.watchTenants();
});

final contractsProvider = StreamProvider.autoDispose<List<Contract>>((ref) {
  final controller = ref.watch(contractControllerProvider);
  return controller.watchContracts();
});

final paymentsProvider = StreamProvider.autoDispose<List<Payment>>((ref) {
  final controller = ref.watch(paymentControllerProvider);
  return controller.watchPayments();
});

final expensesProvider = StreamProvider.autoDispose<List<PropertyExpense>>((
  ref,
) {
  final controller = ref.watch(expenseControllerProvider);
  return controller.watchExpenses();
});

/// Provider pour le bilan des dépenses Immobilier.
final immobilierExpenseBalanceProvider =
    StreamProvider.autoDispose<List<ExpenseBalanceData>>((ref) {
      return ref.watch(expensesProvider.stream).map((expenses) {
        final adapter = ImmobilierExpenseBalanceAdapter();
        return adapter.convertToBalanceData(expenses);
      });
    });

/// Provider pour les contrats d'un locataire spécifique.
final contractsByTenantProvider = StreamProvider.autoDispose
    .family<List<Contract>, String>((ref, tenantId) {
      return ref
          .watch(contractsProvider.stream)
          .map(
            (contracts) =>
                contracts.where((c) => c.tenantId == tenantId).toList(),
          );
    });

/// Provider pour les paiements d'un contrat spécifique.
final paymentsByContractProvider = StreamProvider.autoDispose
    .family<List<Payment>, String>((ref, contractId) {
      return ref
          .watch(paymentsProvider.stream)
          .map(
            (payments) =>
                payments.where((p) => p.contractId == contractId).toList(),
          );
    });

/// Provider pour les contrats d'une propriété spécifique.
final contractsByPropertyProvider = StreamProvider.autoDispose
    .family<List<Contract>, String>((ref, propertyId) {
      return ref
          .watch(contractsProvider.stream)
          .map(
            (contracts) =>
                contracts.where((c) => c.propertyId == propertyId).toList(),
          );
    });

/// Provider pour tous les paiements d'un locataire (via ses contrats).
final paymentsByTenantProvider = StreamProvider.autoDispose
    .family<List<Payment>, String>((ref, tenantId) {
      return CombineLatestStream.combine2(
        ref.watch(contractsByTenantProvider(tenantId).stream),
        ref.watch(paymentsProvider.stream),
        (contracts, payments) {
          final contractIds = contracts.map((c) => c.id).toSet();
          final filtered =
              payments
                  .where((p) => contractIds.contains(p.contractId))
                  .toList();
          // Trier par date décroissante
          filtered.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
          return filtered;
        },
      );
    });

// Filter Services
final paymentFilterServiceProvider = Provider<PaymentFilterService>(
  (ref) => PaymentFilterService(),
);

final expenseFilterServiceProvider = Provider<ExpenseFilterService>(
  (ref) => ExpenseFilterService(),
);
