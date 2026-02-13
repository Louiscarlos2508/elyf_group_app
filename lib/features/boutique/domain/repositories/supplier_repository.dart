import '../entities/supplier.dart';

abstract class SupplierRepository {
  Future<List<Supplier>> fetchSuppliers({int limit = 100});
  Future<Supplier?> getSupplier(String id);
  Future<String> createSupplier(Supplier supplier);
  Future<void> updateSupplier(Supplier supplier);
  Future<void> deleteSupplier(String id);
  Stream<List<Supplier>> watchSuppliers({int limit = 100});
  Future<List<Supplier>> searchSuppliers(String query);
}
