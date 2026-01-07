import 'dart:developer' as developer;

import 'collections/agent_collection.dart';
import 'collections/contract_collection.dart';
import 'collections/customer_collection.dart';
import 'collections/expense_collection.dart';
import 'collections/machine_collection.dart';
import 'collections/payment_collection.dart';
import 'collections/product_collection.dart';
import 'collections/production_session_collection.dart';
import 'collections/property_collection.dart';
import 'collections/sale_collection.dart';
import 'collections/tenant_collection.dart';
import 'collections/transaction_collection.dart';

/// Stub Isar database interface.
///
/// Provides a no-op implementation of Isar methods for offline-first
/// functionality. All operations complete without actually storing data.
class StubIsar {
  final StubIsarCollection<SaleCollection> saleCollections =
      StubIsarCollection<SaleCollection>();

  final StubIsarCollection<SaleItemCollection> saleItemCollections =
      StubIsarCollection<SaleItemCollection>();

  final StubIsarCollection<ContractCollection> contractCollections =
      StubIsarCollection<ContractCollection>();

  final StubIsarCollection<ExpenseCollection> expenseCollections =
      StubIsarCollection<ExpenseCollection>();

  final StubIsarCollection<PaymentCollection> paymentCollections =
      StubIsarCollection<PaymentCollection>();

  final StubIsarCollection<PropertyCollection> propertyCollections =
      StubIsarCollection<PropertyCollection>();

  final StubIsarCollection<TenantCollection> tenantCollections =
      StubIsarCollection<TenantCollection>();

  final StubIsarCollection<AgentCollection> agentCollections =
      StubIsarCollection<AgentCollection>();

  final StubIsarCollection<TransactionCollection> transactionCollections =
      StubIsarCollection<TransactionCollection>();

  final StubIsarCollection<CustomerCollection> customerCollections =
      StubIsarCollection<CustomerCollection>();

  final StubIsarCollection<MachineCollection> machineCollections =
      StubIsarCollection<MachineCollection>();

  final StubIsarCollection<ProductCollection> productCollections =
      StubIsarCollection<ProductCollection>();

  final StubIsarCollection<ProductionSessionCollection>
      productionSessionCollections =
      StubIsarCollection<ProductionSessionCollection>();

  /// Execute a write transaction.
  Future<T> writeTxn<T>(Future<T> Function() callback) async {
    return await callback();
  }

  /// Execute a read transaction.
  Future<T> txn<T>(Future<T> Function() callback) async {
    return await callback();
  }
}

/// Stub collection that provides query builder interface.
class StubIsarCollection<T> {
  /// Put an object into the collection.
  Future<int> put(T object) async => 0;

  /// Put all objects into the collection.
  Future<List<int>> putAll(List<T> objects) async =>
      List.generate(objects.length, (i) => i);

  /// Delete an object by id.
  Future<bool> delete(int id) async => true;

  /// Get object by id.
  Future<T?> get(int id) async => null;

  /// Create a query builder.
  StubQueryBuilder<T> filter() => StubQueryBuilder<T>();

  /// Get all objects.
  Future<List<T>> where() async => [];
}

/// Stub query builder for fluent query API.
class StubQueryBuilder<T> {
  /// Add an equals filter.
  StubQueryBuilder<T> equalTo(dynamic value) => this;

  /// String field equals filter.
  StubQueryBuilder<T> localIdEqualTo(String value) => this;
  StubQueryBuilder<T> remoteIdEqualTo(String value) => this;
  StubQueryBuilder<T> enterpriseIdEqualTo(String value) => this;
  StubQueryBuilder<T> moduleTypeEqualTo(String value) => this;
  StubQueryBuilder<T> saleLocalIdEqualTo(String value) => this;
  StubQueryBuilder<T> contractIdEqualTo(String value) => this;
  StubQueryBuilder<T> propertyIdEqualTo(String value) => this;
  StubQueryBuilder<T> tenantIdEqualTo(String value) => this;
  StubQueryBuilder<T> relatedEntityTypeEqualTo(String value) => this;
  StubQueryBuilder<T> relatedEntityIdEqualTo(String value) => this;
  StubQueryBuilder<T> productIdEqualTo(String value) => this;
  StubQueryBuilder<T> customerIdEqualTo(String value) => this;
  StubQueryBuilder<T> machineIdEqualTo(String value) => this;
  StubQueryBuilder<T> sessionIdEqualTo(String value) => this;
  StubQueryBuilder<T> categoryEqualTo(String value) => this;
  StubQueryBuilder<T> statusEqualTo(String value) => this;
  StubQueryBuilder<T> barcodeEqualTo(String value) => this;
  StubQueryBuilder<T> nameContains(String value) => this;

  /// And combinator.
  StubQueryBuilder<T> and() => this;

  /// Or combinator.
  StubQueryBuilder<T> or() => this;

  /// Sort by date descending.
  StubQueryBuilder<T> sortBySaleDateDesc() => this;
  StubQueryBuilder<T> sortByDateDesc() => this;
  StubQueryBuilder<T> sortByCreatedAtDesc() => this;
  StubQueryBuilder<T> sortByUpdatedAtDesc() => this;
  StubQueryBuilder<T> sortByExpenseDateDesc() => this;
  StubQueryBuilder<T> sortByNameAsc() => this;
  StubQueryBuilder<T> sortByStartDateDesc() => this;
  
  /// Date range queries.
  StubQueryBuilder<T> expenseDateGreaterThan(DateTime value) => this;
  StubQueryBuilder<T> expenseDateLessThan(DateTime value) => this;

  /// Find first matching object.
  Future<T?> findFirst() async => null;

  /// Find all matching objects.
  Future<List<T>> findAll() async => [];

  /// Delete all matching objects.
  Future<int> deleteAll() async => 0;

  /// Count matching objects.
  Future<int> count() async => 0;
}

/// Stub IsarService - Isar is temporarily disabled due to SDK incompatibility.
///
/// TODO: Migrate to ObjectBox for offline-first functionality.
/// ObjectBox has a similar API to Isar and is actively maintained.
class IsarService {
  IsarService._();

  static IsarService? _instance;
  bool _initialized = false;

  final StubIsar _isar = StubIsar();

  /// Singleton instance of the service.
  static IsarService get instance {
    _instance ??= IsarService._();
    return _instance!;
  }

  /// Whether the database is initialized.
  bool get isInitialized => _initialized;

  /// Get the Isar database instance.
  StubIsar get isar => _isar;

  /// Current database version for migrations.
  static const int currentVersion = 1;

  /// Initializes the service (stub - no-op).
  Future<void> initialize() async {
    if (_initialized) {
      developer.log(
        'IsarService already initialized (stub)',
        name: 'offline.stub',
      );
      return;
    }

    developer.log(
      'IsarService initialized (stub - offline disabled)',
      name: 'offline.stub',
    );
    _initialized = true;
  }

  /// Clears all data (stub - no-op).
  Future<void> clearAll() async {
    developer.log(
      'IsarService.clearAll called (stub)',
      name: 'offline.stub',
    );
  }

  /// Clears enterprise data (stub - no-op).
  Future<void> clearEnterpriseData(String enterpriseId) async {
    developer.log(
      'IsarService.clearEnterpriseData called for: $enterpriseId (stub)',
      name: 'offline.stub',
    );
  }

  /// Gets pending sync count (stub returns 0).
  Future<int> getPendingSyncCount() async => 0;

  /// Gets database statistics (stub returns empty stats).
  Future<Map<String, int>> getStats() async => {
        'enterprises': 0,
        'sales': 0,
        'products': 0,
        'expenses': 0,
        'customers': 0,
        'agents': 0,
        'transactions': 0,
        'properties': 0,
        'tenants': 0,
        'contracts': 0,
        'payments': 0,
        'machines': 0,
        'bobines': 0,
        'productionSessions': 0,
        'syncMetadata': 0,
        'pendingOperations': 0,
      };

  /// Closes the service (stub - no-op).
  Future<void> close() async {
    _initialized = false;
    developer.log(
      'IsarService closed (stub)',
      name: 'offline.stub',
    );
  }

  /// Disposes the singleton instance.
  static Future<void> dispose() async {
    await _instance?.close();
    _instance = null;
  }
}
