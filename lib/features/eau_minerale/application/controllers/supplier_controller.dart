import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../../../core/logging/app_logger.dart';

class SupplierController {
  SupplierController(this._supplierRepository);

  final SupplierRepository _supplierRepository;

  Future<List<Supplier>> fetchSuppliers() async {
    try {
      return await _supplierRepository.fetchSuppliers();
    } catch (e) {
      AppLogger.error('Error fetching suppliers', error: e);
      rethrow;
    }
  }

  Stream<List<Supplier>> watchSuppliers() {
    return _supplierRepository.watchSuppliers();
  }

  Future<String> createSupplier(Supplier supplier) async {
    try {
      return await _supplierRepository.createSupplier(supplier);
    } catch (e) {
      AppLogger.error('Error creating supplier', error: e);
      rethrow;
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      await _supplierRepository.updateSupplier(supplier);
    } catch (e) {
      AppLogger.error('Error updating supplier', error: e);
      rethrow;
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _supplierRepository.deleteSupplier(id);
    } catch (e) {
      AppLogger.error('Error deleting supplier', error: e);
      rethrow;
    }
  }

  Future<List<Supplier>> searchSuppliers(String query) async {
    return await _supplierRepository.searchSuppliers(query);
  }
}
