import '../../domain/entities/product.dart';
import '../../domain/product_roles.dart';
import '../../domain/repositories/product_repository.dart';

/// Controller pour gérer les produits.
class ProductController {
  ProductController(this._repository, this.enterpriseId);

  final ProductRepository _repository;
  final String enterpriseId;

  /// Garantit la présence des produits par défaut (Pack, Bobine, Emballage) avec leurs rôles.
  Future<void> seedDefaultProducts() async {
    final products = await _repository.fetchProducts();

    // 1. Pack
    final hasPack = products.any((p) => p.role == ProductRoles.mainFinishedGood);
    if (!hasPack) {
      await _repository.createProduct(Product(
        id: 'pf_pack_${DateTime.now().millisecondsSinceEpoch}',
        enterpriseId: enterpriseId,
        name: 'Pack d\'eau minérale',
        type: ProductType.finishedGood,
        role: ProductRoles.mainFinishedGood,
        unitPrice: 200,
        unit: 'Unité',
        description: 'Pack standard de bouteilles',
      ));
    }

    // 2. Bobine
    final hasBobine = products.any((p) => p.role == ProductRoles.mainBobine);
    if (!hasBobine) {
      await _repository.createProduct(Product(
        id: 'mp_bobine_${DateTime.now().millisecondsSinceEpoch}',
        enterpriseId: enterpriseId,
        name: 'Bobine',
        type: ProductType.rawMaterial,
        role: ProductRoles.mainBobine,
        unitPrice: 0,
        unit: 'Unité',
        description: 'Bobine de film plastique',
      ));
    }

    // 3. Emballage
    final hasEmballage = products.any((p) => p.role == ProductRoles.mainPackaging);
    if (!hasEmballage) {
      await _repository.createProduct(Product(
        id: 'mp_emballage_${DateTime.now().millisecondsSinceEpoch}',
        enterpriseId: enterpriseId,
        name: 'Emballage',
        type: ProductType.rawMaterial,
        role: ProductRoles.mainPackaging,
        unitPrice: 0,
        unit: 'Unité',
        unitsPerLot: 1000,
        supplyUnit: 'Paquet',
        description: 'Sacs d\'emballage pour les packs',
      ));
    }
  }

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
