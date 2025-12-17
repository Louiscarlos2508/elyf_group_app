import '../entities/sale.dart';

/// Sales management repository.
abstract class SaleRepository {
  Future<List<Sale>> fetchSales({
    DateTime? startDate,
    DateTime? endDate,
    SaleStatus? status,
    String? customerId,
  });
  Future<Sale?> getSale(String id);
  Future<String> createSale(Sale sale);
  Future<void> deleteSale(String saleId);
  /// Updates the amount paid for a sale (used when recording credit payments).
  Future<void> updateSaleAmountPaid(String saleId, int newAmountPaid);
}
