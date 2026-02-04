import '../entities/sale.dart';

/// Sales management repository.
abstract class SaleRepository {
  Future<List<Sale>> fetchSales({
    DateTime? startDate,
    DateTime? endDate,
    SaleStatus? status,
    String? customerId,
  });
  
  Stream<List<Sale>> watchSales({
    DateTime? startDate,
    DateTime? endDate,
    SaleStatus? status,
    String? customerId,
  });

  /// Fetches recent sales (last N sales, sorted by date descending).
  Future<List<Sale>> fetchRecentSales({int limit = 50});
  Future<Sale?> getSale(String id);
  Future<String> createSale(Sale sale);
  Future<void> deleteSale(String saleId);

  /// Updates the amount paid for a sale (used when recording credit payments).
  Future<void> updateSaleAmountPaid(String saleId, int newAmountPaid);
}
