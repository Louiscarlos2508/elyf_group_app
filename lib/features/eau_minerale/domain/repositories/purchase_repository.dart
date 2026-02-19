import '../entities/purchase.dart';

abstract class PurchaseRepository {
  Future<List<Purchase>> fetchPurchases({int limit = 100});
  Future<Purchase?> getPurchase(String id);
  Future<String> createPurchase(Purchase purchase);
  Future<void> updatePurchase(Purchase purchase);
  Future<void> deletePurchase(String id);
  Stream<List<Purchase>> watchPurchases({int limit = 100, String? supplierId});
  
  /// Validates a Purchase Order (Draft) into a confirmed Purchase.
  Future<void> validatePurchaseOrder(String purchaseId);
}
