import '../entities/cylinder.dart';
import '../entities/delivery.dart';
import '../entities/gas_sale.dart';

/// Interface pour le repository de gestion du gaz.
abstract class GasRepository {
  // Cylinders
  Future<List<Cylinder>> getCylinders();
  Future<Cylinder?> getCylinderById(String id);
  Future<void> addCylinder(Cylinder cylinder);
  Future<void> updateCylinder(Cylinder cylinder);
  Future<void> deleteCylinder(String id);

  // Sales
  Future<List<GasSale>> getSales({DateTime? from, DateTime? to});
  Future<GasSale?> getSaleById(String id);
  Future<void> addSale(GasSale sale);
  Future<void> updateSale(GasSale sale);
  Future<void> deleteSale(String id);

  // Deliveries
  Future<List<Delivery>> getDeliveries({DateTime? from, DateTime? to});
  Future<Delivery?> getDeliveryById(String id);
  Future<void> addDelivery(Delivery delivery);
  Future<void> updateDelivery(Delivery delivery);
  Future<void> deleteDelivery(String id);
}
