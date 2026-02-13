import 'package:drift/drift.dart';

@DataClassName('SaleEntity')
class SalesTable extends Table {
  TextColumn get id => text()(); // localId
  TextColumn get enterpriseId => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get totalAmount => integer()();
  IntColumn get amountPaid => integer()();
  TextColumn get customerName => text().nullable()();
  TextColumn get paymentMethod => text().nullable()(); // 'cash', 'mobileMoney', 'both'
  TextColumn get notes => text().nullable()();
  IntColumn get cashAmount => integer().withDefault(const Constant(0))();
  IntColumn get mobileMoneyAmount => integer().withDefault(const Constant(0))();
  
  TextColumn get number => text().nullable()(); // Numéro de facture
  
  // Security
  TextColumn get ticketHash => text().nullable()(); // SHA-256 Signature
  TextColumn get previousHash => text().nullable()(); // Chain integrity

  // Sync & Meta
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deletedBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
