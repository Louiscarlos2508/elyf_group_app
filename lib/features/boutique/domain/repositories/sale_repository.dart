import '../entities/sale.dart';

/// Repository for managing sales.
abstract class SaleRepository {
  Future<List<Sale>> fetchRecentSales({int limit = 50});
  Future<String> createSale(Sale sale);
  Future<Sale?> getSale(String id);
}

