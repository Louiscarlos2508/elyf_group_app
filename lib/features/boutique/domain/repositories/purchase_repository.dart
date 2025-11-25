import '../entities/purchase.dart';

/// Repository for managing purchases.
abstract class PurchaseRepository {
  Future<List<Purchase>> fetchPurchases({int limit = 50});
  Future<Purchase?> getPurchase(String id);
  Future<String> createPurchase(Purchase purchase);
}

