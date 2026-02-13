import 'package:drift/drift.dart';

@DataClassName('PropertyEntity')
class PropertiesTable extends Table {
  TextColumn get id => text()(); // localId
  TextColumn get enterpriseId => text()();
  TextColumn get address => text()();
  TextColumn get city => text()();
  TextColumn get propertyType => text()(); // house, apartment, studio, villa, commercial
  IntColumn get rooms => integer()();
  IntColumn get area => integer()(); // en m²
  IntColumn get price => integer()(); // prix de location mensuel en FCFA
  TextColumn get status => text()(); // available, rented, maintenance, sold
  TextColumn get description => text().nullable()();
  TextColumn get images => text().nullable()(); // Serialized List<String>
  TextColumn get amenities => text().nullable()(); // Serialized List<String>
  
  // Security & Audit
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deletedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
