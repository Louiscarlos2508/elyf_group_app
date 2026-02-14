import 'package:drift/drift.dart';

@DataClassName('PropertyExpenseEntity')
class PropertyExpensesTable extends Table {
  TextColumn get id => text()(); // localId
  TextColumn get enterpriseId => text()();
  TextColumn get propertyId => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get category => text()(); // maintenance, repair, utilities, insurance, taxes, cleaning, other
  TextColumn get description => text()();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  TextColumn get receipt => text().nullable()(); // URL or path to receipt
  
  // Security & Audit
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deletedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
