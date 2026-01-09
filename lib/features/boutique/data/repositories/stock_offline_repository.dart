import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/stock_repository.dart';

/// Offline-first repository for Stock (boutique module).
///
/// Délègue à ProductRepository car le stock est géré directement dans Product.
class StockOfflineRepository implements StockRepository {
  StockOfflineRepository(this._productRepository);

  final ProductRepository _productRepository;

  @override
  Future<void> updateStock(String productId, int quantity) async {
    final product = await _productRepository.getProduct(productId);
    if (product != null) {
      await _productRepository.updateProduct(
        product.copyWith(stock: quantity),
      );
    }
  }

  @override
  Future<int> getStock(String productId) async {
    final product = await _productRepository.getProduct(productId);
    return product?.stock ?? 0;
  }

  @override
  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    final products = await _productRepository.fetchProducts();
    return products.where((p) => p.stock <= threshold).toList();
  }
}

