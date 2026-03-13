import '../../domain/entities/product.dart';
import '../../domain/product_roles.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/stock_repository.dart';

/// Controller pour gérer les produits.
class ProductController {
  ProductController(this._repository, this._stockRepository, this.enterpriseId);

  final ProductRepository _repository;
  final StockRepository _stockRepository;
  final String enterpriseId;

  /// Récupère tous les produits.
  Future<List<Product>> fetchProducts() async {
    return _repository.fetchProducts();
  }

  /// Récupère un produit par son ID.
  Future<Product?> getProduct(String id) async {
    return _repository.getProduct(id);
  }

  /// Récupère un produit par son rôle.
  Future<Product?> getProductByRole(String role) async {
    // Essayer via le repository s'il l'implémente, sinon via fetchProducts
    try {
      return await _repository.getProductByRole(role);
    } catch (_) {
      final all = await fetchProducts();
      try {
        return all.firstWhere((p) => p.role == role);
      } catch (_) {
        return null;
      }
    }
  }

  /// Crée un nouveau produit.
  Future<String> createProduct(Product product) async {
    return _repository.createProduct(product);
  }

  /// Met à jour un produit existant.
  Future<void> updateProduct(Product product) async {
    return _repository.updateProduct(product);
  }

  /// Supprime un produit.
  Future<void> deleteProduct(String id) async {
    return _repository.deleteProduct(id);
  }
}
