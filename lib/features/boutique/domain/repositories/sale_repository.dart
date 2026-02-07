import '../entities/sale.dart';

/// Repository for managing sales.
abstract class SaleRepository {
  Future<List<Sale>> fetchRecentSales({int limit = 50});
  Future<String> createSale(Sale sale);
  Future<Sale?> getSale(String id);
  Future<List<Sale>> getSalesInPeriod(DateTime start, DateTime end);
  Stream<List<Sale>> watchRecentSales({int limit = 50});
}
