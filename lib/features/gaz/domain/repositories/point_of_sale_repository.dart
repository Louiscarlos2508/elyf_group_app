import '../entities/point_of_sale.dart';

/// Repository pour la gestion des points de vente.
abstract class PointOfSaleRepository {
  /// Récupère tous les points de vente pour une entreprise et un module.
  Future<List<PointOfSale>> getPointsOfSale({
    required String enterpriseId,
    required String moduleId,
  });

  Stream<List<PointOfSale>> watchPointsOfSale({
    required String enterpriseId,
    required String moduleId,
  });

  /// Récupère un point de vente par son ID.
  Future<PointOfSale?> getPointOfSaleById(String id);

  /// Ajoute un nouveau point de vente.
  Future<void> addPointOfSale(PointOfSale pointOfSale);

  /// Met à jour un point de vente existant.
  Future<void> updatePointOfSale(PointOfSale pointOfSale);

  /// Supprime un point de vente.
  Future<void> deletePointOfSale(String id);
}
