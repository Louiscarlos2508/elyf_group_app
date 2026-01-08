import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

/// Controller pour gérer les produits.
class ProductController {
  ProductController(this._repository);

  final ProductRepository _repository;

  /// Récupère tous les produits.
  Future<List<Product>> fetchProducts() async {
    return await _repository.fetchProducts();
  }

  /// Récupère un produit par son ID.
  Future<Product?> getProduct(String id) async {
    return await _repository.getProduct(id);
  }

  /// Crée un nouveau produit.
  Future<String> createProduct(Product product) async {
    return await _repository.createProduct(product);
  }

  /// Met à jour un produit existant.
  Future<void> updateProduct(Product product) async {
    return await _repository.updateProduct(product);
  }

  /// Supprime un produit.
  Future<void> deleteProduct(String id) async {
    return await _repository.deleteProduct(id);
  }
}

