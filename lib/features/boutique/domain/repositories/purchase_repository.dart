import '../entities/purchase.dart';

/// Repository for managing purchases.
abstract class PurchaseRepository {
  Future<List<Purchase>> fetchPurchases({int limit = 50});
  Future<Purchase?> getPurchase(String id);
  Future<String> createPurchase(Purchase purchase);
  Future<List<Purchase>> getPurchasesInPeriod(DateTime start, DateTime end);
  Future<int> getCountForDate(DateTime date);
  Future<void> deletePurchase(String id, {String? deletedBy});
  Future<void> restorePurchase(String id);
  Future<List<Purchase>> getDeletedPurchases();
  Stream<List<Purchase>> watchPurchases({int limit = 50});
  Stream<List<Purchase>> watchDeletedPurchases();
  Future<bool> verifyChain();
}
