import 'dart:async';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class MockProductRepository implements ProductRepository {
  final _products = <String, Product>{
    'product-1': const Product(
      id: 'product-1',
      name: 'Pack',
      type: ProductType.finishedGood,
      unitPrice: 200,
      unit: 'Unité',
    ),
    'product-2': const Product(
      id: 'product-2',
      name: 'Sachets',
      type: ProductType.rawMaterial,
      unitPrice: 25,
      unit: 'kg',
    ),
    'product-3': const Product(
      id: 'product-3',
      name: 'Bidons',
      type: ProductType.rawMaterial,
      unitPrice: 50,
      unit: 'Unité',
    ),
  };

  @override
  Future<List<Product>> fetchProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _products.values.toList();
  }

  @override
  Future<Product?> getProduct(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _products[id];
  }

  @override
  Future<String> createProduct(Product product) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final id = 'product-${_products.length + 1}';
    _products[id] = Product(
      id: id,
      name: product.name,
      type: product.type,
      unitPrice: product.unitPrice,
      unit: product.unit,
      description: product.description,
    );
    return id;
  }

  @override
  Future<void> updateProduct(Product product) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _products[product.id] = product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _products.remove(id);
  }
}
