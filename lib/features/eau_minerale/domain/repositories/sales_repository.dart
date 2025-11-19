import '../entities/sale.dart';

/// Provides access to sales, credits, and repayments.
abstract class SalesRepository {
  Future<List<Sale>> fetchRecentSales({int limit = 20});
  Future<String> createSale(Sale sale);
}
