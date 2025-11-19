import '../entities/sale.dart';

/// Sales management repository with validation workflow.
abstract class SaleRepository {
  Future<List<Sale>> fetchSales({
    DateTime? startDate,
    DateTime? endDate,
    SaleStatus? status,
    String? customerId,
  });
  Future<List<Sale>> fetchPendingSales();
  Future<Sale?> getSale(String id);
  Future<String> createSale(Sale sale);
  Future<void> validateSale(String saleId, String validatedBy);
  Future<void> rejectSale(String saleId, String rejectedBy);
  Future<void> deleteSale(String saleId);
}
