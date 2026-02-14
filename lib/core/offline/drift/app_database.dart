import 'package:drift/drift.dart';

import 'connection.dart';
import '../../../../features/boutique/data/datasources/local/tables/sales_table.dart';
import '../../../../features/boutique/data/datasources/local/tables/sale_items_table.dart';
import '../../../../features/immobilier/data/datasources/local/tables/properties_table.dart';
import '../../../../features/immobilier/data/datasources/local/tables/tenants_table.dart';
import '../../../../features/immobilier/data/datasources/local/tables/contracts_table.dart';
import '../../../../features/immobilier/data/datasources/local/tables/payments_table.dart';
import '../../../../features/immobilier/data/datasources/local/tables/expenses_table.dart';
import '../../../../features/immobilier/data/datasources/local/tables/maintenance_table.dart';

part 'app_database.g.dart';

/// Generic offline storage used by all modules.
///
/// We store each entity as JSON (dataJson) with a small set of indexed columns
/// for multi-tenant filtering and sync.
class OfflineRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get collectionName => text()(); // e.g. "sales", "products"
  TextColumn get localId => text()(); // local_... id (always set)
  TextColumn get remoteId => text().nullable()(); // Firestore doc id (optional)

  TextColumn get enterpriseId => text()();
  TextColumn get moduleType => text().withDefault(const Constant(''))();

  TextColumn get dataJson => text()(); // serialized Map<String, dynamic>
  DateTimeColumn get localUpdatedAt => dateTime()();

  @override
  List<String> get customConstraints => [
    'UNIQUE(collection_name, enterprise_id, module_type, local_id)',
  ];
}

/// Queue of sync operations to be processed.
///
/// Stores pending create, update, and delete operations that need to be
/// synchronized with Firestore.
class SyncOperations extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get operationType => text()(); // 'create', 'update', 'delete'
  TextColumn get collectionName => text()();
  TextColumn get documentId => text()(); // localId or remoteId
  TextColumn get enterpriseId => text()();
  TextColumn get payload =>
      text().nullable()(); // JSON payload for create/update
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get processedAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // 'pending', 'processing', 'synced', 'failed'
  DateTimeColumn get localUpdatedAt => dateTime()();
  IntColumn get priority => integer().withDefault(const Constant(2))(); // 0=critical, 1=high, 2=normal, 3=low

  @override
  List<String> get customConstraints => [
    'UNIQUE(operation_type, collection_name, document_id, enterprise_id, status)',
  ];
}

@DriftDatabase(tables: [
  OfflineRecords,
  SyncOperations,
  SalesTable,
  SaleItemsTable,
  PropertiesTable,
  TenantsTable,
  ContractsTable,
  ImmobilierPaymentsTable,
  PropertyExpensesTable,
  MaintenanceTicketsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor? connection) : super(connection ?? openDriftConnection());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.createTable(syncOperations);
          // Add table for Boutique sales if updating from < v2
          await migrator.createTable(salesTable);
          await migrator.createTable(saleItemsTable);
        }
        if (from < 3) {
          await migrator.addColumn(syncOperations, syncOperations.priority);
        }
        if (from < 4) {
          // This block is now redundant if from < 2 creates salesTable and saleItemsTable
          // but keeping it for faithful reproduction of the provided migration logic.
          // The provided instruction's migration logic for from < 2 already creates salesTable and saleItemsTable.
          // The original code had this:
          // await migrator.createTable(salesTable);
          // await migrator.createTable(saleItemsTable);
        } else if (from < 5) {
          // Only add if not created in step 4
          await migrator.addColumn(salesTable, salesTable.number as GeneratedColumn<String>);
        }
        if (from < 6) {
          await migrator.createTable(propertiesTable);
          await migrator.createTable(tenantsTable);
          await migrator.createTable(contractsTable);
          await migrator.createTable(immobilierPaymentsTable);
        }
        if (from < 7) {
          await migrator.createTable(propertyExpensesTable);
        }
        if (from < 8) {
          await migrator.createTable(maintenanceTicketsTable);
        }
        if (from < 9) {
          await migrator.addColumn(propertyExpensesTable, propertyExpensesTable.paymentMethod as GeneratedColumn<String>);
        }
      },
    );
  }
}
