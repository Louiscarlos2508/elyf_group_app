import '../../domain/entities/cylinder.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/repositories/gas_repository.dart';

/// Implémentation mock du repository gaz.
class MockGasRepository implements GasRepository {
  // Les bouteilles sont maintenant gérées dynamiquement via l'écran de paramètres
  // La liste est vide par défaut, l'utilisateur doit créer les bouteilles
  final List<Cylinder> _cylinders = [];

  final List<GasSale> _sales = [];
  final List<Delivery> _deliveries = [];

  @override
  Future<List<Cylinder>> getCylinders() async => List.from(_cylinders);

  @override
  Future<Cylinder?> getCylinderById(String id) async {
    return _cylinders.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<void> addCylinder(Cylinder cylinder) async {
    _cylinders.add(cylinder);
  }

  @override
  Future<void> updateCylinder(Cylinder cylinder) async {
    final index = _cylinders.indexWhere((c) => c.id == cylinder.id);
    if (index != -1) _cylinders[index] = cylinder;
  }

  @override
  Future<void> deleteCylinder(String id) async {
    _cylinders.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<GasSale>> getSales({DateTime? from, DateTime? to}) async {
    return _sales.where((s) {
      if (from != null && s.saleDate.isBefore(from)) return false;
      if (to != null && s.saleDate.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<GasSale?> getSaleById(String id) async {
    return _sales.where((s) => s.id == id).firstOrNull;
  }

  @override
  Future<void> addSale(GasSale sale) async {
    _sales.add(sale);
  }

  @override
  Future<void> updateSale(GasSale sale) async {
    final index = _sales.indexWhere((s) => s.id == sale.id);
    if (index != -1) _sales[index] = sale;
  }

  @override
  Future<void> deleteSale(String id) async {
    _sales.removeWhere((s) => s.id == id);
  }

  @override
  Future<List<Delivery>> getDeliveries({DateTime? from, DateTime? to}) async {
    return _deliveries.where((d) {
      if (from != null && d.deliveryDate.isBefore(from)) return false;
      if (to != null && d.deliveryDate.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<Delivery?> getDeliveryById(String id) async {
    return _deliveries.where((d) => d.id == id).firstOrNull;
  }

  @override
  Future<void> addDelivery(Delivery delivery) async {
    _deliveries.add(delivery);
  }

  @override
  Future<void> updateDelivery(Delivery delivery) async {
    final index = _deliveries.indexWhere((d) => d.id == delivery.id);
    if (index != -1) _deliveries[index] = delivery;
  }

  @override
  Future<void> deleteDelivery(String id) async {
    _deliveries.removeWhere((d) => d.id == id);
  }
}
