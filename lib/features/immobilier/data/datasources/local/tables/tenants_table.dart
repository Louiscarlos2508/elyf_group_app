import 'package:drift/drift.dart';

@DataClassName('TenantEntity')
class TenantsTable extends Table {
  TextColumn get id => text()(); // localId
  TextColumn get enterpriseId => text()();
  TextColumn get fullName => text()();
  TextColumn get phone => text()();
  TextColumn get address => text().nullable()();
  TextColumn get idNumber => text().nullable()();
  TextColumn get emergencyContact => text().nullable()();
  TextColumn get idCardPath => text().nullable()();
  TextColumn get notes => text().nullable()();
  
  // Security & Audit
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deletedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
