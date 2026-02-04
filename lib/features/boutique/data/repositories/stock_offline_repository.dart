import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/stock_repository.dart';

/// Offline-first repository for Stock management.
///
/// This repository wraps the ProductRepository to manage stock operations
/// since stock is stored as part of the Product entity.
class StockOfflineRepository implements StockRepository {
  StockOfflineRepository({required this.productRepository});

  final ProductRepository productRepository;

  @override
  Future<void> updateStock(String productId, int quantity) async {
    try {
      AppLogger.debug(
        'Updating stock for product: $productId to $quantity',
        name: 'StockOfflineRepository',
      );
      final product = await productRepository.getProduct(productId);
      if (product != null) {
        final updatedProduct = product.copyWith(stock: quantity);
        await productRepository.updateProduct(updatedProduct);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating stock for product: $productId - ${appException.message}',
        name: 'StockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<int> getStock(String productId) async {
    try {
      final product = await productRepository.getProduct(productId);
      return product?.stock ?? 0;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting stock for product: $productId - ${appException.message}',
        name: 'StockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    try {
      AppLogger.debug(
        'Getting low stock products with threshold: $threshold',
        name: 'StockOfflineRepository',
      );
      final products = await productRepository.fetchProducts();
      return products.where((p) => p.stock <= threshold).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting low stock products: ${appException.message}',
        name: 'StockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<int> watchStock(String productId) {
    return productRepository.watchProducts().map((products) {
      try {
        final product = products.firstWhere((p) => p.id == productId);
        return product.stock;
      } catch (_) {
        return 0;
      }
    });
  }

  @override
  Stream<List<Product>> watchLowStockProducts({int threshold = 10}) {
    return productRepository
        .watchProducts()
        .map((products) => products.where((p) => p.stock <= threshold).toList());
  }
}
