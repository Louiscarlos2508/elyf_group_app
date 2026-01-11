import 'dart:async';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class MockProductRepository implements ProductRepository {
  final _products = <String, Product>{};

  MockProductRepository() {
    _initMockData();
  }

  void _initMockData() {
    final products = [
      Product(
        id: 'prod-1',
        name: 'Riz 5kg',
        price: 2500,
        stock: 50,
        category: 'Alimentaire',
        barcode: '1234567890123',
      ),
      Product(
        id: 'prod-2',
        name: 'Huile 1L',
        price: 1500,
        stock: 30,
        category: 'Alimentaire',
        barcode: '1234567890124',
      ),
      Product(
        id: 'prod-3',
        name: 'Sucre 1kg',
        price: 800,
        stock: 25,
        category: 'Alimentaire',
        barcode: '1234567890125',
      ),
      Product(
        id: 'prod-4',
        name: 'Savon',
        price: 500,
        stock: 100,
        category: 'Hygiène',
        barcode: '1234567890126',
      ),
      Product(
        id: 'prod-5',
        name: 'Pâtes 500g',
        price: 600,
        stock: 15,
        category: 'Alimentaire',
        barcode: '1234567890127',
      ),
      Product(
        id: 'prod-6',
        name: 'Lait en poudre 400g',
        price: 2000,
        stock: 20,
        category: 'Alimentaire',
        barcode: '1234567890128',
      ),
      Product(
        id: 'prod-7',
        name: 'Biscuits',
        price: 300,
        stock: 5,
        category: 'Alimentaire',
        barcode: '1234567890129',
      ),
      Product(
        id: 'prod-8',
        name: 'Détergent',
        price: 1200,
        stock: 40,
        category: 'Entretien',
        barcode: '1234567890130',
      ),
    ];

    for (final product in products) {
      _products[product.id] = product;
    }
  }

  @override
  Future<List<Product>> fetchProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _products.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<Product?> getProduct(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _products[id];
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _products.values.firstWhere(
      (p) => p.barcode == barcode,
      orElse: () => throw StateError('Product not found'),
    );
  }

  @override
  Future<String> createProduct(Product product) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _products[product.id] = product;
    return product.id;
  }

  @override
  Future<void> updateProduct(Product product) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _products[product.id] = product;
  }

  @override
  Future<void> deleteProduct(String id, {String? deletedBy}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final product = _products[id];
    if (product != null && !product.isDeleted) {
      _products[id] = product.copyWith(
        deletedAt: DateTime.now(),
        deletedBy: deletedBy,
      );
    }
  }

  @override
  Future<void> restoreProduct(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final product = _products[id];
    if (product != null && product.isDeleted) {
      _products[id] = product.copyWith(
        deletedAt: null,
        deletedBy: null,
      );
    }
  }

  @override
  Future<List<Product>> getDeletedProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _products.values
        .where((p) => p.isDeleted)
        .toList()
      ..sort((a, b) => (b.deletedAt ?? DateTime(1970))
          .compareTo(a.deletedAt ?? DateTime(1970)));
  }
}

