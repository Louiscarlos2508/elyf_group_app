import 'dart:developer' as developer;

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
    developer.log(
      'PointOfSaleController.getPointsOfSale: enterpriseId=$enterpriseId, moduleId=$moduleId',
      name: 'PointOfSaleController',
    );
    final result = await _repository.getPointsOfSale(
      enterpriseId: enterpriseId,
      moduleId: moduleId,
    );
    developer.log(
      'PointOfSaleController.getPointsOfSale: trouvé ${result.length} points de vente',
      name: 'PointOfSaleController',
    );
    return result;
  }

  /// Observe les points de vente en temps réel.
  Stream<List<PointOfSale>> watchPointsOfSale({
    required String enterpriseId,
    required String moduleId,
  }) {
    return _repository.watchPointsOfSale(
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
