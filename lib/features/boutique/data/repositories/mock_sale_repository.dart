import 'dart:async';

import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';

class MockSaleRepository implements SaleRepository {
  final _sales = <Sale>[];

  MockSaleRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    _sales.addAll([
      Sale(
        id: 'sale-1',
        date: now.subtract(const Duration(hours: 2)),
        items: [
          SaleItem(
            productId: 'prod-1',
            productName: 'Riz 5kg',
            quantity: 2,
            unitPrice: 2500,
            totalPrice: 5000,
          ),
          SaleItem(
            productId: 'prod-2',
            productName: 'Huile 1L',
            quantity: 1,
            unitPrice: 1500,
            totalPrice: 1500,
          ),
        ],
        totalAmount: 6500,
        amountPaid: 7000,
        paymentMethod: PaymentMethod.cash,
      ),
      Sale(
        id: 'sale-2',
        date: now.subtract(const Duration(hours: 5)),
        items: [
          SaleItem(
            productId: 'prod-4',
            productName: 'Savon',
            quantity: 3,
            unitPrice: 500,
            totalPrice: 1500,
          ),
        ],
        totalAmount: 1500,
        amountPaid: 1500,
        paymentMethod: PaymentMethod.mobileMoney,
      ),
    ]);
  }

  @override
  Future<List<Sale>> fetchRecentSales({int limit = 50}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _sales.take(limit).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<String> createSale(Sale sale) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _sales.insert(0, sale);
    return sale.id;
  }

  @override
  Future<Sale?> getSale(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    try {
      return _sales.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

