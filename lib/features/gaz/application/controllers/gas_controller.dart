import 'package:flutter/material.dart';

import '../../domain/entities/cylinder.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/repositories/gas_repository.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/errors/app_exceptions.dart';

/// Contrôleur pour la gestion des ventes de gaz.
class GasController extends ChangeNotifier {
  GasController(this._repository, this._auditTrailService);

  final GasRepository _repository;
  final AuditTrailService _auditTrailService;
  bool _isLoading = false;
  List<Cylinder> _cylinders = [];
  List<GasSale> _sales = [];

  bool get isLoading => _isLoading;
  List<Cylinder> get cylinders => _cylinders;
  List<GasSale> get sales => _sales;

  Stream<List<Cylinder>> watchCylinders() {
    return _repository.watchCylinders();
  }

  Stream<List<GasSale>> watchSales({DateTime? from, DateTime? to, List<String>? enterpriseIds}) {
    return _repository.watchSales(from: from, to: to, enterpriseIds: enterpriseIds);
  }

  Future<void> loadCylinders() async {
    _isLoading = true;
    notifyListeners();

    _cylinders = await _repository.getCylinders();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSales({DateTime? from, DateTime? to, List<String>? enterpriseIds}) async {
    _isLoading = true;
    notifyListeners();

    _sales = await _repository.getSales(from: from, to: to, enterpriseIds: enterpriseIds);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSale(GasSale sale) async {
    final cylinder = await _repository.getCylinderById(sale.cylinderId);
    if (cylinder == null) {
      throw BusinessException('Bouteille introuvable');
    }
    if (sale.quantity > cylinder.stock) {
      throw BusinessException(
        'Stock insuffisant pour ${cylinder.label}. Disponible: ${cylinder.stock}',
      );
    }
    await _repository.addSale(sale);

    // Audit Log
    try {
      if (sale.createdBy != null) {
        await _auditTrailService.logSale(
          enterpriseId: sale.enterpriseId,
          userId: sale.createdBy!,
          saleId: sale.id,
          module: 'gaz',
          totalAmount: sale.totalAmount.toDouble(),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to log gas sale audit', error: e);
    }

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

  /// Updates the stock of a cylinder after a sale.
  Future<void> updateCylinderStock(String cylinderId, int newStock) async {
    final cylinderIndex = _cylinders.indexWhere((c) => c.id == cylinderId);
    if (cylinderIndex != -1) {
      _cylinders[cylinderIndex] = _cylinders[cylinderIndex].copyWith(
        stock: newStock,
      );
      await _repository.updateCylinder(_cylinders[cylinderIndex]);
      notifyListeners();
    }
  }
}
