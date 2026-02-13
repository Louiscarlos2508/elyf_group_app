import 'package:drift/drift.dart';
import 'sales_table.dart';

@DataClassName('SaleItemEntity')
class SaleItemsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get saleId => text().references(SalesTable, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  IntColumn get unitPrice => integer()();
  IntColumn get purchasePrice => integer().nullable()();
  IntColumn get totalPrice => integer()();
}
