import 'dart:async';

import '../../domain/entities/cylinder.dart';
import '../../domain/entities/depot.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/repositories/gas_repository.dart';

/// Mock implementation of GasRepository for development.
class MockGasRepository implements GasRepository {
  final _cylinders = <String, Cylinder>{};
  final _sales = <String, GasSale>{};
  final _depots = <String, Depot>{};

  MockGasRepository() {
    // Initialize with sample data
    _depots['depot-1'] = const Depot(
      id: 'depot-1',
      name: 'Dépôt Central',
      address: 'Ouagadougou, Zone 30',
      phoneNumber: '+22670123456',
      managerName: 'Amadou Traoré',
      totalCylinders: 500,
      availableCylinders: 350,
    );

    _cylinders['cyl-1'] = const Cylinder(
      id: 'cyl-1',
      size: CylinderSize.kg12,
      status: CylinderStatus.available,
      depotId: 'depot-1',
    );

    final now = DateTime.now();
    _sales['sale-1'] = GasSale(
      id: 'sale-1',
      type: SaleType.retail,
      cylinderSize: CylinderSize.kg12,
      quantity: 1,
      unitPrice: 15000,
      totalPrice: 15000,
      date: now.subtract(const Duration(hours: 2)),
      status: SaleStatus.completed,
      customerName: 'Jean Dupont',
      customerPhone: '+22670123456',
      depotId: 'depot-1',
    );

    _sales['sale-2'] = GasSale(
      id: 'sale-2',
      type: SaleType.wholesale,
      cylinderSize: CylinderSize.kg12,
      quantity: 10,
      unitPrice: 14000,
      totalPrice: 140000,
      date: now.subtract(const Duration(hours: 1)),
      status: SaleStatus.completed,
      customerName: 'SARL Gaz Plus',
      customerPhone: '+22670234567',
      depotId: 'depot-1',
    );
  }

  @override
  Future<List<Cylinder>> fetchCylinders({
    String? depotId,
    CylinderSize? size,
    CylinderStatus? status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    var cylinders = _cylinders.values.toList();

    if (depotId != null) {
      cylinders = cylinders.where((c) => c.depotId == depotId).toList();
    }

    if (size != null) {
      cylinders = cylinders.where((c) => c.size == size).toList();
    }

    if (status != null) {
      cylinders = cylinders.where((c) => c.status == status).toList();
    }

    return cylinders;
  }

  @override
  Future<List<GasSale>> fetchSales({
    DateTime? startDate,
    DateTime? endDate,
    SaleType? type,
    String? depotId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    var sales = _sales.values.toList();

    if (startDate != null) {
      sales = sales
          .where((s) => s.date.isAfter(startDate) || s.date.isAtSameMomentAs(startDate))
          .toList();
    }

    if (endDate != null) {
      sales = sales
          .where((s) => s.date.isBefore(endDate) || s.date.isAtSameMomentAs(endDate))
          .toList();
    }

    if (type != null) {
      sales = sales.where((s) => s.type == type).toList();
    }

    if (depotId != null) {
      sales = sales.where((s) => s.depotId == depotId).toList();
    }

    sales.sort((a, b) => b.date.compareTo(a.date));
    return sales;
  }

  @override
  Future<List<Depot>> fetchDepots() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _depots.values.toList();
  }

  @override
  Future<String> createSale(GasSale sale) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _sales[sale.id] = sale;
    return sale.id;
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final sales = await fetchSales(startDate: startDate, endDate: endDate);

    final retailTotal = sales
        .where((s) => s.isRetail && s.isCompleted)
        .fold<int>(0, (sum, s) => sum + s.totalPrice);

    final wholesaleTotal = sales
        .where((s) => s.isWholesale && s.isCompleted)
        .fold<int>(0, (sum, s) => sum + s.totalPrice);

    final totalCylinders = _cylinders.length;
    final availableCylinders = _cylinders.values
        .where((c) => c.status == CylinderStatus.available)
        .length;

    return {
      'totalSales': sales.length,
      'retailTotal': retailTotal,
      'wholesaleTotal': wholesaleTotal,
      'totalCylinders': totalCylinders,
      'availableCylinders': availableCylinders,
    };
  }
}

