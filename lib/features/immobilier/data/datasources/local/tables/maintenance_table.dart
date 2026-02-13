import 'package:drift/drift.dart';

class MaintenanceTicketsTable extends Table {
  TextColumn get id => text()(); // localId
  TextColumn get enterpriseId => text()();
  TextColumn get propertyId => text()();
  TextColumn get tenantId => text().nullable()();
  TextColumn get description => text()();
  TextColumn get priority => text()(); // low, medium, high, critical
  TextColumn get status => text()(); // open, inProgress, resolved, closed
  TextColumn get photos => text().nullable()(); // Serialized List<String>
  RealColumn get cost => real().nullable()();

  // Security & Audit
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deletedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
