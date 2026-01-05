import '../../domain/entities/point_of_sale.dart';
import '../../domain/repositories/point_of_sale_repository.dart';

/// Implémentation mock du repository des points de vente.
/// Utilise une liste statique pour conserver les données entre les instances.
class MockPointOfSaleRepository implements PointOfSaleRepository {
  // Liste statique pour conserver les données entre les instances
  static final List<PointOfSale> _pointsOfSale = [];

  @override
  Future<List<PointOfSale>> getPointsOfSale({
    required String enterpriseId,
    required String moduleId,
  }) async {
    return _pointsOfSale
        .where((pos) =>
            pos.enterpriseId == enterpriseId && pos.moduleId == moduleId)
        .toList();
  }

  @override
  Future<PointOfSale?> getPointOfSaleById(String id) async {
    return _pointsOfSale.where((pos) => pos.id == id).firstOrNull;
  }

  @override
  Future<void> addPointOfSale(PointOfSale pointOfSale) async {
    _pointsOfSale.add(pointOfSale);
  }

  @override
  Future<void> updatePointOfSale(PointOfSale pointOfSale) async {
    final index = _pointsOfSale.indexWhere((pos) => pos.id == pointOfSale.id);
    if (index != -1) {
      _pointsOfSale[index] = pointOfSale;
    }
  }

  @override
  Future<void> deletePointOfSale(String id) async {
    _pointsOfSale.removeWhere((pos) => pos.id == id);
  }
}

