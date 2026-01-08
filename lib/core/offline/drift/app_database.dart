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

@DriftDatabase(tables: [OfflineRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDriftConnection());

  @override
  int get schemaVersion => 1;
}


