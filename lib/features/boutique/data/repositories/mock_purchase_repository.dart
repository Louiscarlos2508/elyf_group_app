import 'dart:async';

import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';

class MockPurchaseRepository implements PurchaseRepository {
  final _purchases = <String, Purchase>{};

  MockPurchaseRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    final purchases = [
      Purchase(
        id: 'purchase-1',
        date: now.subtract(const Duration(days: 2)),
        supplier: 'Fournisseur ABC',
        items: [
          PurchaseItem(
            productId: 'prod-1',
            productName: 'Riz 5kg',
            quantity: 20,
            purchasePrice: 2000,
            totalPrice: 40000,
          ),
          PurchaseItem(
            productId: 'prod-2',
            productName: 'Huile 1L',
            quantity: 15,
            purchasePrice: 1200,
            totalPrice: 18000,
          ),
        ],
        totalAmount: 58000,
        notes: 'Commande régulière',
      ),
      Purchase(
        id: 'purchase-2',
        date: now.subtract(const Duration(days: 5)),
        supplier: 'Fournisseur XYZ',
        items: [
          PurchaseItem(
            productId: 'prod-3',
            productName: 'Sucre 1kg',
            quantity: 30,
            purchasePrice: 650,
            totalPrice: 19500,
          ),
        ],
        totalAmount: 19500,
      ),
    ];

    for (final purchase in purchases) {
      _purchases[purchase.id] = purchase;
    }
  }

  @override
  Future<List<Purchase>> fetchPurchases({int limit = 50}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _purchases.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<Purchase?> getPurchase(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _purchases[id];
  }

  @override
  Future<String> createPurchase(Purchase purchase) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _purchases[purchase.id] = purchase;
    return purchase.id;
  }
}

