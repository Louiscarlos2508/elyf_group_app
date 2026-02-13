import '../entities/supplier_settlement.dart';

abstract class SupplierSettlementRepository {
  Future<List<SupplierSettlement>> fetchSettlements({String? supplierId, int limit = 100});
  Future<String> createSettlement(SupplierSettlement settlement);
  Future<void> deleteSettlement(String id, {String? deletedBy});
  Future<SupplierSettlement?> getSettlement(String id);
  Stream<List<SupplierSettlement>> watchSettlements({String? supplierId, int limit = 100});
  Stream<List<SupplierSettlement>> watchDeletedSettlements({String? supplierId});
  Future<int> getCountForDate(DateTime date);
}
