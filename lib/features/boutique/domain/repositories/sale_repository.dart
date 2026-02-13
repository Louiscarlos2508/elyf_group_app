import '../entities/sale.dart';

/// Repository for managing sales.
abstract class SaleRepository {
  Future<List<Sale>> fetchRecentSales({int limit = 50});
  Future<Sale> createSale(Sale sale);
  Future<Sale?> getSale(String id);
  Future<List<Sale>> getSalesInPeriod(DateTime start, DateTime end);
  Future<int> getCountForDate(DateTime date);
  Future<void> deleteSale(String id, {String? deletedBy});
  Future<void> restoreSale(String id);
  Future<List<Sale>> getDeletedSales();
  Stream<List<Sale>> watchRecentSales({int limit = 50});
  Stream<List<Sale>> watchDeletedSales();
  Future<bool> verifyChain();
  Future<List<Sale>> fetchSales({int limit = 1000});
}
