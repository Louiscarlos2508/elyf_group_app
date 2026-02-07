import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

export 'providers/permission_providers.dart';
export 'providers/section_providers.dart';
export 'providers/filter_providers.dart';

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

// --- Services ---

final immobilierReportCalculationServiceProvider =
    Provider<ImmobilierReportCalculationService>(
      (ref) => ImmobilierReportCalculationService(),
    );

final immobilierDashboardCalculationServiceProvider =
    Provider<ImmobilierDashboardCalculationService>(
      (ref) => ImmobilierDashboardCalculationService(),
    );

final propertyCalculationServiceProvider = Provider<PropertyCalculationService>(
  (ref) => PropertyCalculationService(),
);

final propertyValidationServiceProvider = Provider<PropertyValidationService>(
  (ref) => PropertyValidationService(),
);

final contractValidationServiceProvider = Provider<ContractValidationService>(
  (ref) => ContractValidationService(),
);

final paymentFilterServiceProvider = Provider<PaymentFilterService>(
  (ref) => PaymentFilterService(),
);

final expenseFilterServiceProvider = Provider<ExpenseFilterService>(
  (ref) => ExpenseFilterService(),
);

// --- Repositories ---

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

final immobilierValidationServiceProvider =
    Provider<ImmobilierValidationService>(
      (ref) => ImmobilierValidationService(
        ref.watch(propertyRepositoryProvider),
        ref.watch(contractRepositoryProvider),
        ref.watch(paymentRepositoryProvider),
      ),
    );

// --- Controllers ---

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

// --- Basic Data Providers ---

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

final contractsWithRelationsProvider = StreamProvider.autoDispose<List<Contract>>((ref) {
  final contractsStream = ref.watch(contractControllerProvider).watchContracts();
  final tenantsStream = ref.watch(tenantControllerProvider).watchTenants();
  final propertiesStream = ref.watch(propertyControllerProvider).watchProperties();

  return CombineLatestStream.combine3(
    contractsStream,
    tenantsStream,
    propertiesStream,
    (contracts, tenants, properties) {
      return contracts.map((c) {
        final tenant = tenants.where((t) => t.id == c.tenantId).firstOrNull;
        final property = properties.where((p) => p.id == c.propertyId).firstOrNull;
        return c.copyWith(tenant: tenant, property: property);
      }).toList();
    },
  );
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

// --- Deleted Items Providers ---

final deletedPropertiesProvider = StreamProvider.autoDispose<List<Property>>((
  ref,
) {
  final controller = ref.watch(propertyControllerProvider);
  return controller.watchDeletedProperties();
});

final deletedTenantsProvider = StreamProvider.autoDispose<List<Tenant>>((ref) {
  final controller = ref.watch(tenantControllerProvider);
  return controller.watchDeletedTenants();
});

final deletedContractsProvider = StreamProvider.autoDispose<List<Contract>>((
  ref,
) {
  final controller = ref.watch(contractControllerProvider);
  return controller.watchDeletedContracts();
});

final deletedPaymentsProvider = StreamProvider.autoDispose<List<Payment>>((ref) {
  final controller = ref.watch(paymentControllerProvider);
  return controller.watchDeletedPayments();
});

final deletedExpensesProvider = StreamProvider.autoDispose<List<PropertyExpense>>((
  ref,
) {
  final controller = ref.watch(expenseControllerProvider);
  return controller.watchDeletedExpenses();
});

// --- Combined & Derived Providers ---

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
      ref.watch(propertyControllerProvider).watchProperties(),
      ref.watch(tenantControllerProvider).watchTenants(),
      ref.watch(contractControllerProvider).watchContracts(),
      ref.watch(paymentControllerProvider).watchPayments(),
      ref.watch(expenseControllerProvider).watchExpenses(),
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

final immobilierAlertsProvider = StreamProvider.autoDispose<
    ({List<Payment> payments, List<Contract> contracts})>(
  (ref) {
    return CombineLatestStream.combine2(
      ref.watch(paymentControllerProvider).watchPayments(),
      ref.watch(contractControllerProvider).watchContracts(),
      (payments, contracts) => (
        payments: payments,
        contracts: contracts,
      ),
    );
  },
);

final immobilierExpenseBalanceProvider =
    StreamProvider.autoDispose<List<ExpenseBalanceData>>((ref) {
      return ref.watch(expenseControllerProvider).watchExpenses().map((expenses) {
        final adapter = ImmobilierExpenseBalanceAdapter();
        return adapter.convertToBalanceData(expenses);
      });
    });

final contractsByTenantProvider = StreamProvider.autoDispose
    .family<List<Contract>, String>((ref, tenantId) {
      return ref.watch(contractControllerProvider).watchContracts().map(
        (contracts) => contracts.where((c) => c.tenantId == tenantId).toList(),
      );
    });

final paymentsByContractProvider = StreamProvider.autoDispose
    .family<List<Payment>, String>((ref, contractId) {
      return ref.watch(paymentControllerProvider).watchPayments().map(
        (payments) => payments.where((p) => p.contractId == contractId).toList(),
      );
    });

final contractsByPropertyProvider = StreamProvider.autoDispose
    .family<List<Contract>, String>((ref, propertyId) {
      return ref.watch(contractControllerProvider).watchContracts().map(
        (contracts) => contracts.where((c) => c.propertyId == propertyId).toList(),
      );
    });

final paymentsByTenantProvider = StreamProvider.autoDispose
    .family<List<Payment>, String>((ref, tenantId) {
      return CombineLatestStream.combine2(
        ref.watch(contractControllerProvider).watchContracts().map(
          (contracts) => contracts.where((c) => c.tenantId == tenantId).toList(),
        ),
        ref.watch(paymentControllerProvider).watchPayments(),
        (contracts, payments) {
          final contractIds = contracts.map((c) => c.id).toSet();
          final filtered =
              payments
                  .where((p) => contractIds.contains(p.contractId))
                  .toList();
          filtered.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
          return filtered;
        },
      );
    });
final propertyProfitabilityProvider = StreamProvider.autoDispose
    .family<({int revenue, int expenses, int net}), String>((ref, propertyId) {
      return CombineLatestStream.combine3(
        ref.watch(contractControllerProvider).watchContracts().map(
          (contracts) => contracts.where((c) => c.propertyId == propertyId),
        ),
        ref.watch(paymentControllerProvider).watchPayments(),
        ref.watch(expenseControllerProvider).watchExpenses().map(
          (expenses) => expenses.where((e) => e.propertyId == propertyId),
        ),
        (contracts, payments, propertyExpenses) {
          final contractIds = contracts.map((c) => c.id).toSet();
          
          final revenue = payments
              .where((p) => contractIds.contains(p.contractId) && p.status != PaymentStatus.cancelled)
              .fold(0, (sum, p) => sum + p.amount);

          final expenses = propertyExpenses
              .where((e) => e.deletedAt == null)
              .fold(0, (sum, e) => sum + e.amount);

          return (
            revenue: revenue,
            expenses: expenses,
            net: revenue - expenses,
          );
        },
      );
    });
