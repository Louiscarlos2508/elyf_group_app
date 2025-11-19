import '../entities/product.dart';

/// Product catalog management repository.
abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
  Future<Product?> getProduct(String id);
  Future<String> createProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);
}
