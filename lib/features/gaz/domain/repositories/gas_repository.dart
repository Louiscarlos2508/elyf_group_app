import '../entities/cylinder.dart';
import '../entities/gas_sale.dart';

/// Interface pour le repository de gestion du gaz.
abstract class GasRepository {
  // Cylinders
  Future<List<Cylinder>> getCylinders();
  Stream<List<Cylinder>> watchCylinders();
  Future<Cylinder?> getCylinderById(String id);
  Future<void> addCylinder(Cylinder cylinder);
  Future<void> updateCylinder(Cylinder cylinder);
  Future<void> deleteCylinder(String id);

  // Sales
  Future<List<GasSale>> getSales({DateTime? from, DateTime? to, List<String>? enterpriseIds});
  Stream<List<GasSale>> watchSales({DateTime? from, DateTime? to, List<String>? enterpriseIds});
  Future<GasSale?> getSaleById(String id);
  Future<void> addSale(GasSale sale);
  Future<void> updateSale(GasSale sale);
  Future<void> deleteSale(String id);
}
