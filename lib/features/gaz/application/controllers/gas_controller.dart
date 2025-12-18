import 'package:flutter/material.dart';

import '../../domain/entities/cylinder.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/repositories/gas_repository.dart';

/// Contrôleur pour la gestion des ventes de gaz.
class GasController extends ChangeNotifier {
  GasController(this._repository);

  final GasRepository _repository;

  List<Cylinder> _cylinders = [];
  List<GasSale> _sales = [];
  bool _isLoading = false;

  List<Cylinder> get cylinders => _cylinders;
  List<GasSale> get sales => _sales;
  bool get isLoading => _isLoading;

  Future<void> loadCylinders() async {
    _isLoading = true;
    notifyListeners();

    _cylinders = await _repository.getCylinders();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSales({DateTime? from, DateTime? to}) async {
    _isLoading = true;
    notifyListeners();

    _sales = await _repository.getSales(from: from, to: to);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSale(GasSale sale) async {
    await _repository.addSale(sale);
    await loadSales();
  }

  Future<void> updateSale(GasSale sale) async {
    await _repository.updateSale(sale);
    await loadSales();
  }

  Future<void> deleteSale(String id) async {
    await _repository.deleteSale(id);
    await loadSales();
  }

  Future<void> updateCylinderStock(String cylinderId, int quantity) async {
    final cylinder = await _repository.getCylinderById(cylinderId);
    if (cylinder != null) {
      await _repository.updateCylinder(
        cylinder.copyWith(stock: cylinder.stock + quantity),
      );
      await loadCylinders();
    }
  }
}
