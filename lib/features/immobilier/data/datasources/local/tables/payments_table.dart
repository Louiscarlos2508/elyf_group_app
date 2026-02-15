import 'package:drift/drift.dart';

@DataClassName('ImmobilierPaymentEntity')
class ImmobilierPaymentsTable extends Table {
  TextColumn get id => text()(); // localId
  TextColumn get enterpriseId => text()();
  TextColumn get contractId => text()();
  IntColumn get amount => integer()();
  IntColumn get paidAmount => integer().withDefault(const Constant(0))();
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get paymentMethod => text()(); // cash, mobileMoney, both, bankTransfer
  TextColumn get status => text()(); // paid, pending, overdue, cancelled
  IntColumn get month => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get receiptNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get paymentType => text().nullable()(); // rent, deposit
  IntColumn get cashAmount => integer().nullable()();
  IntColumn get mobileMoneyAmount => integer().nullable()();
  IntColumn get penaltyAmount => integer().withDefault(const Constant(0))();
  // Security & Audit
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deletedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
