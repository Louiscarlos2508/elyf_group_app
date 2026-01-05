import '../../domain/entities/point_of_sale.dart';
import '../../domain/repositories/point_of_sale_repository.dart';

/// Contrôleur pour la gestion des points de vente.
class PointOfSaleController {
  PointOfSaleController(this._repository);

  final PointOfSaleRepository _repository;

  /// Récupère tous les points de vente pour une entreprise et un module.
  Future<List<PointOfSale>> getPointsOfSale({
    required String enterpriseId,
    required String moduleId,
  }) async {
    return _repository.getPointsOfSale(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );
  }

  /// Récupère un point de vente par son ID.
  Future<PointOfSale?> getPointOfSaleById(String id) async {
    return _repository.getPointOfSaleById(id);
  }

  /// Ajoute un nouveau point de vente.
  Future<void> addPointOfSale(PointOfSale pointOfSale) async {
    await _repository.addPointOfSale(pointOfSale);
  }

  /// Met à jour un point de vente existant.
  Future<void> updatePointOfSale(PointOfSale pointOfSale) async {
    await _repository.updatePointOfSale(pointOfSale);
  }

  /// Supprime un point de vente.
  Future<void> deletePointOfSale(String id) async {
    await _repository.deletePointOfSale(id);
  }
}

