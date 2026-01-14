import '../entities/cylinder_stock.dart';
import '../entities/cylinder.dart';

/// Interface pour le repository de gestion des stocks de bouteilles.
abstract class CylinderStockRepository {
  Future<List<CylinderStock>> getStocksByStatus(
    String enterpriseId,
    CylinderStatus status, {
    String? siteId,
  });

  Future<List<CylinderStock>> getStocksByWeight(
    String enterpriseId,
    int weight, {
    String? siteId,
  });

  Future<CylinderStock?> getStockById(String id);

  Future<void> updateStockQuantity(String id, int newQuantity);

  Future<void> changeStockStatus(String id, CylinderStatus newStatus);

  Future<List<CylinderStock>> getStockBySite(
    String enterpriseId,
    String siteId,
  );

  Future<void> addStock(CylinderStock stock);

  Future<void> updateStock(CylinderStock stock);

  Future<void> deleteStock(String id);
}
