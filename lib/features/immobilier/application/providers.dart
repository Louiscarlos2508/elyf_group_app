import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_contract_repository.dart';
import '../data/repositories/mock_expense_repository.dart';
import '../data/repositories/mock_payment_repository.dart';
import '../data/repositories/mock_property_repository.dart';
import '../data/repositories/mock_tenant_repository.dart';
import '../domain/entities/contract.dart';
import '../domain/entities/expense.dart';
import '../domain/entities/payment.dart';
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
import 'services/immobilier_validation_service.dart';

// Repositories
final propertyRepositoryProvider = Provider<PropertyRepository>(
  (ref) => MockPropertyRepository(),
);

final tenantRepositoryProvider = Provider<TenantRepository>(
  (ref) => MockTenantRepository(),
);

final contractRepositoryProvider = Provider<ContractRepository>(
  (ref) => MockContractRepository(),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => MockPaymentRepository(),
);

final expenseRepositoryProvider = Provider<PropertyExpenseRepository>(
  (ref) => MockPropertyExpenseRepository(),
);

// Validation Service
final immobilierValidationServiceProvider = Provider<ImmobilierValidationService>(
  (ref) => ImmobilierValidationService(
    ref.watch(propertyRepositoryProvider),
    ref.watch(contractRepositoryProvider),
    ref.watch(paymentRepositoryProvider),
  ),
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

