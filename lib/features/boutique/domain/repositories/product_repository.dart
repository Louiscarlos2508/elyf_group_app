import '../entities/product.dart';

/// Repository for managing products.
abstract class ProductRepository {
  Future<List<Product>> fetchProducts();
  Future<Product?> getProduct(String id);
  Future<Product?> getProductByBarcode(String barcode);
  Future<String> createProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id, {String? deletedBy});
  Future<void> restoreProduct(String id);
  Future<List<Product>> getDeletedProducts();
  Stream<List<Product>> watchProducts();
  Stream<List<Product>> watchDeletedProducts();
}
