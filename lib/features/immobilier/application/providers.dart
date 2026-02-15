import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';

import 'providers/filter_providers.dart'; 
import '../../audit_trail/application/providers.dart';
import 'providers/permission_providers.dart' show currentUserIdProvider;
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/providers.dart' as core_providers;
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
import '../domain/entities/immobilier_settings.dart';
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
import 'services/receipt_service.dart';
import 'services/billing_automation_service.dart';
import '../domain/services/dashboard_calculation_service.dart';
import '../domain/services/filtering/expense_filter_service.dart';
import '../domain/services/filtering/payment_filter_service.dart';
import '../domain/services/immobilier_validation_service.dart';
import '../domain/services/property_calculation_service.dart';
import '../domain/services/property_validation_service.dart';
import '../domain/services/validation/contract_validation_service.dart';
import '../data/repositories/maintenance_offline_repository.dart';
import '../domain/entities/maintenance_ticket.dart';
import '../domain/repositories/maintenance_repository.dart';
import 'controllers/maintenance_controller.dart';
import '../domain/entities/treasury_operation.dart';
import '../domain/repositories/treasury_repository.dart';
import '../data/repositories/treasury_offline_repository.dart';
import 'controllers/immobilier_treasury_controller.dart';
import '../domain/services/immobilier_settings_service.dart';
import '../../../../core/printing/printer_provider.dart';
import '../domain/services/calculation/immobilier_report_calculation_service.dart';
import '../domain/repositories/immobilier_settings_repository.dart';
import '../data/repositories/immobilier_settings_offline_repository.dart';

export 'providers/permission_providers.dart';
export 'providers/section_providers.dart';
export 'providers/filter_providers.dart';

// --- Settings & Hardware ---

final immobilierSettingsServiceProvider = Provider<ImmobilierSettingsService>((ref) {
  final prefs = ref.watch(core_providers.sharedPreferencesProvider);
  return ImmobilierSettingsService(prefs);
});

final immobilierSettingsProvider = StreamProvider.family<ImmobilierSettings?, String>((ref, enterpriseId) {
  final repository = ref.watch(immobilierSettingsRepositoryProvider);
  return repository.watchSettings(enterpriseId);
});

final immobilierPrinterConfigProvider = Provider<PrinterConfig>((ref) {
  final settings = ref.watch(immobilierSettingsServiceProvider);
  return PrinterConfig(
    type: settings.printerType,
    address: settings.printerAddress,
  );
});

// --- Services ---

final billingAutomationServiceProvider = Provider<BillingAutomationService>((ref) {
  final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
  final enterpriseId = activeEnterprise?.id ?? 'default';
  final userId = ref.watch(currentUserIdProvider);

  return BillingAutomationService(
    ref.watch(contractRepositoryProvider),
    ref.watch(paymentRepositoryProvider),
    ref.watch(immobilierSettingsRepositoryProvider),
    ref.watch(auditTrailServiceProvider),
    enterpriseId,
    userId,
  );
});

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
  final syncManager = ref.watch(core_providers.syncManagerProvider);
  final connectivityService = ref.watch(core_providers.connectivityServiceProvider);

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
  final syncManager = ref.watch(core_providers.syncManagerProvider);
  final connectivityService = ref.watch(core_providers.connectivityServiceProvider);

  return TenantOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
  );
});

final immobilierSettingsRepositoryProvider = Provider<ImmobilierSettingsRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(core_providers.syncManagerProvider);
  final connectivityService = ref.watch(core_providers.connectivityServiceProvider);

  return ImmobilierSettingsOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    currentEnterpriseId: enterpriseId,
  );
});

final contractRepositoryProvider = Provider<ContractRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(core_providers.syncManagerProvider);
  final connectivityService = ref.watch(core_providers.connectivityServiceProvider);

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
  final syncManager = ref.watch(core_providers.syncManagerProvider);
  final connectivityService = ref.watch(core_providers.connectivityServiceProvider);

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
  final syncManager = ref.watch(core_providers.syncManagerProvider);
  final connectivityService = ref.watch(core_providers.connectivityServiceProvider);

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
    ref.watch(auditTrailServiceProvider),
    ref.watch(activeEnterpriseProvider).value?.id ?? 'default',
    ref.watch(currentUserIdProvider) ?? 'unknown',
  ),
);

final tenantControllerProvider = Provider<TenantController>(
  (ref) => TenantController(
    ref.watch(tenantRepositoryProvider),
    ref.watch(immobilierValidationServiceProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(activeEnterpriseProvider).value?.id ?? 'default',
    ref.watch(currentUserIdProvider) ?? 'unknown',
  ),
);

final contractControllerProvider = Provider<ContractController>(
  (ref) => ContractController(
    ref.watch(contractRepositoryProvider),
    ref.watch(propertyRepositoryProvider),
    ref.watch(immobilierValidationServiceProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(activeEnterpriseProvider).value?.id ?? 'default',
    ref.watch(currentUserIdProvider) ?? 'unknown',
  ),
);

final paymentControllerProvider = Provider<PaymentController>(
  (ref) => PaymentController(
    ref.watch(paymentRepositoryProvider),
    ref.watch(contractRepositoryProvider),
    ref.watch(tenantRepositoryProvider),
    ref.watch(propertyRepositoryProvider),
    ref.watch(receiptServiceProvider),
    ref.watch(immobilierValidationServiceProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(treasuryControllerProvider),
    ref.watch(activeEnterpriseProvider).value?.id ?? 'default',
    ref.watch(currentUserIdProvider) ?? 'unknown',
  ),
);

final expenseControllerProvider = Provider<PropertyExpenseController>(
  (ref) => PropertyExpenseController(
    ref.watch(expenseRepositoryProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(treasuryControllerProvider),
    ref.watch(activeEnterpriseProvider).value?.id ?? 'default',
    ref.watch(currentUserIdProvider) ?? 'unknown',
  ),
);

// --- Basic Data Providers ---

final propertiesProvider = StreamProvider.autoDispose<List<Property>>((ref) {
  final controller = ref.watch(propertyControllerProvider);
  final filter = ref.watch(archiveFilterProvider);
  return controller.watchProperties(isDeleted: filter.asBool);
});

final tenantsProvider = StreamProvider.autoDispose<List<Tenant>>((ref) {
  final controller = ref.watch(tenantControllerProvider);
  final filter = ref.watch(archiveFilterProvider);
  return controller.watchTenants(isDeleted: filter.asBool);
});

final contractsProvider = StreamProvider.autoDispose<List<Contract>>((ref) {
  final controller = ref.watch(contractControllerProvider);
  final filter = ref.watch(archiveFilterProvider);
  return controller.watchContracts(isDeleted: filter.asBool);
});

final contractsWithRelationsProvider = StreamProvider.autoDispose<List<Contract>>((ref) {
  final filter = ref.watch(archiveFilterProvider);
  final contractsStream = ref.watch(contractControllerProvider).watchContracts(isDeleted: filter.asBool);
  final tenantsStream = ref.watch(tenantControllerProvider).watchTenants(isDeleted: null); 
  final propertiesStream = ref.watch(propertyControllerProvider).watchProperties(isDeleted: null); 

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

final maintenanceTicketsProvider = StreamProvider.autoDispose<List<MaintenanceTicket>>((ref) {
  final controller = ref.watch(maintenanceControllerProvider);
  final filter = ref.watch(archiveFilterProvider);
  return controller.watchAllTickets(isDeleted: filter.asBool);
});

final maintenanceTicketsByPropertyProvider = StreamProvider.autoDispose
    .family<List<MaintenanceTicket>, String>((ref, propertyId) {
      final controller = ref.watch(maintenanceControllerProvider);
      final filter = ref.watch(archiveFilterProvider);
      return controller.watchTicketsByProperty(propertyId, isDeleted: filter.asBool);
    });

final paymentsProvider = StreamProvider.autoDispose<List<Payment>>((ref) {
  final controller = ref.watch(paymentControllerProvider);
  final filter = ref.watch(archiveFilterProvider);
  return controller.watchPayments(isDeleted: filter.asBool);
});

final expensesProvider = StreamProvider.autoDispose<List<PropertyExpense>>((ref) {
  final controller = ref.watch(expenseControllerProvider);
  final filter = ref.watch(archiveFilterProvider);
  return controller.watchExpenses(isDeleted: filter.asBool);
});

final paymentsWithRelationsProvider = StreamProvider.autoDispose<List<Payment>>((ref) {
  final filter = ref.watch(archiveFilterProvider);
  final paymentsStream = ref.watch(paymentControllerProvider).watchPayments(isDeleted: filter.asBool);
  final contractsStream = ref.watch(contractControllerProvider).watchContracts(isDeleted: null);
  final tenantsStream = ref.watch(tenantControllerProvider).watchTenants(isDeleted: null);
  final propertiesStream = ref.watch(propertyControllerProvider).watchProperties(isDeleted: null);

  return CombineLatestStream.combine4<List<Payment>, List<Contract>, List<Tenant>,
      List<Property>, List<Payment>>(
    paymentsStream,
    contractsStream,
    tenantsStream,
    propertiesStream,
    (payments, contracts, tenants, properties) {
      return payments.map((p) {
        final contract =
            contracts.where((c) => c.id == p.contractId).firstOrNull;
        if (contract != null) {
          final tenant =
              tenants.where((t) => t.id == contract.tenantId).firstOrNull;
          final property =
              properties.where((prop) => prop.id == contract.propertyId).firstOrNull;
          return p.copyWith(
            contract: contract.copyWith(tenant: tenant, property: property),
          );
        }
        return p;
      }).toList();
    },
  );
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

final deletedPaymentsWithRelationsProvider =
    StreamProvider.autoDispose<List<Payment>>((ref) {
  final paymentsStream =
      ref.watch(paymentControllerProvider).watchDeletedPayments();
  final contractsStream =
      ref.watch(contractControllerProvider).watchContracts();
  final tenantsStream = ref.watch(tenantControllerProvider).watchTenants();
  final propertiesStream =
      ref.watch(propertyControllerProvider).watchProperties();

  return CombineLatestStream.combine4<List<Payment>, List<Contract>, List<Tenant>,
      List<Property>, List<Payment>>(
    paymentsStream,
    contractsStream,
    tenantsStream,
    propertiesStream,
    (payments, contracts, tenants, properties) {
      return payments.map((p) {
        final contract =
            contracts.where((c) => c.id == p.contractId).firstOrNull;
        if (contract != null) {
          final tenant =
              tenants.where((t) => t.id == contract.tenantId).firstOrNull;
          final property =
              properties.where((prop) => prop.id == contract.propertyId).firstOrNull;
          return p.copyWith(
            contract: contract.copyWith(tenant: tenant, property: property),
          );
        }
        return p;
      }).toList();
    },
  );
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

final activeLeaseForPropertyProvider = StreamProvider.autoDispose.family<Contract?, String>((ref, propertyId) {
  final contractsStream = ref.watch(contractControllerProvider).watchContracts();
  final tenantsStream = ref.watch(tenantControllerProvider).watchTenants();
  
  return CombineLatestStream.combine2(
    contractsStream,
    tenantsStream,
    (contracts, tenants) {
      final contract = contracts.firstWhereOrNull(
        (c) => c.propertyId == propertyId && c.status == ContractStatus.active,
      );
      if (contract == null) return null;
      final tenant = tenants.where((t) => t.id == contract.tenantId).firstOrNull;
      return contract.copyWith(tenant: tenant);
    },
  );
});

final paymentsByTenantProvider = StreamProvider.autoDispose
    .family<List<Payment>, String>((ref, tenantId) {
      return CombineLatestStream.combine2<List<Contract>, List<Payment>, List<Payment>>(
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
      return CombineLatestStream.combine3<Iterable<Contract>, List<Payment>, Iterable<PropertyExpense>, ({int revenue, int expenses, int net})>(
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
              .fold<int>(0, (sum, p) => sum + p.amount);

          final expenses = propertyExpenses
              .where((e) => e.deletedAt == null)
              .fold<int>(0, (sum, e) => sum + e.amount);

          return (
            revenue: revenue,
            expenses: expenses,
            net: revenue - expenses,
          );
        },
      );
    });
// --- Maintenance Providers ---

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(core_providers.syncManagerProvider);
  final connectivityService = ref.watch(core_providers.connectivityServiceProvider);

  return MaintenanceOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
  );
});

final maintenanceControllerProvider = Provider<MaintenanceController>(
  (ref) => MaintenanceController(
    ref.watch(maintenanceRepositoryProvider),
    ref.watch(expenseControllerProvider),
    ref.watch(auditTrailServiceProvider),
    ref.watch(activeEnterpriseProvider).value?.id ?? 'default',
    ref.watch(currentUserIdProvider) ?? 'unknown',
  ),
);


// --- Treasury Providers ---

final treasuryRepositoryProvider = Provider<TreasuryRepository>((ref) {
  final enterpriseId =
      ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
  final driftService = DriftService.instance;
  final syncManager = ref.watch(core_providers.syncManagerProvider);
  final connectivityService = ref.watch(core_providers.connectivityServiceProvider);
  final auditTrailRepo = ref.watch(auditTrailRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return TreasuryOfflineRepository(
    driftService: driftService,
    syncManager: syncManager,
    connectivityService: connectivityService,
    enterpriseId: enterpriseId,
    auditTrailRepository: auditTrailRepo,
    userId: userId,
  );
});

final treasuryControllerProvider = Provider<ImmobilierTreasuryController>(
  (ref) => ImmobilierTreasuryController(
    ref.watch(treasuryRepositoryProvider),
    ref.watch(activeEnterpriseProvider).value?.id ?? 'default',
    ref.watch(currentUserIdProvider) ?? 'unknown',
  ),
);

final treasuryOperationsProvider = StreamProvider.autoDispose<List<TreasuryOperation>>((ref) {
  final controller = ref.watch(treasuryControllerProvider);
  return controller.watchOperations();
});

final treasuryBalancesProvider = FutureProvider.autoDispose<Map<String, int>>((ref) {
  ref.watch(treasuryOperationsProvider);
  final controller = ref.watch(treasuryControllerProvider);
  return controller.getBalances();
});
