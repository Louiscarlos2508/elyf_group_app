import 'package:drift/drift.dart';

import 'connection.dart';

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

  @override
  List<String> get customConstraints => [
    'UNIQUE(operation_type, collection_name, document_id, enterprise_id, status)',
  ];
}

@DriftDatabase(tables: [OfflineRecords, SyncOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDriftConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          // Add sync_operations table
          await migrator.createTable(syncOperations);
        }
      },
    );
  }
}
