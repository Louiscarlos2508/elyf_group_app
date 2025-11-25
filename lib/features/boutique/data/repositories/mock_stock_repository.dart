import 'dart:async';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/stock_repository.dart';

class MockStockRepository implements StockRepository {
  MockStockRepository(this._productRepository);

  final ProductRepository _productRepository;

  @override
  Future<void> updateStock(String productId, int quantity) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final product = await _productRepository.getProduct(productId);
    if (product != null) {
      await _productRepository.updateProduct(
        product.copyWith(stock: quantity),
      );
    }
  }

  @override
  Future<int> getStock(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final product = await _productRepository.getProduct(productId);
    return product?.stock ?? 0;
  }

  @override
  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final products = await _productRepository.fetchProducts();
    return products.where((p) => p.stock <= threshold).toList();
  }
}

