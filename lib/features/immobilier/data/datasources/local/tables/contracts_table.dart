import 'package:drift/drift.dart';

@DataClassName('ContractEntity')
class ContractsTable extends Table {
  TextColumn get id => text()(); // localId
  TextColumn get enterpriseId => text()();
  TextColumn get propertyId => text()();
  TextColumn get tenantId => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get monthlyRent => integer()();
  IntColumn get deposit => integer()();
  TextColumn get status => text()(); // active, expired, terminated, pending
  IntColumn get paymentDay => integer().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get depositInMonths => integer().nullable()();
  TextColumn get entryInventory => text().nullable()();
  TextColumn get exitInventory => text().nullable()();
  
  // Security & Audit
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deletedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
