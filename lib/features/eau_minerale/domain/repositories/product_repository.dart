import '../entities/product.dart';

/// Product management repository.
abstract class ProductRepository {
  Future<List<Product>> fetchAllProducts();
  Future<List<Product>> fetchActiveProducts(ProductType? type);
  Future<Product?> getProduct(String id);
  Future<String> createProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);
}
