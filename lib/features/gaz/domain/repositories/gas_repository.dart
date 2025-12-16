import '../entities/cylinder.dart';
import '../entities/depot.dart';
import '../entities/gas_sale.dart';

/// Repository for managing gas operations.
abstract class GasRepository {
  Future<List<Cylinder>> fetchCylinders({
    String? depotId,
    CylinderSize? size,
    CylinderStatus? status,
  });

  Future<List<GasSale>> fetchSales({
    DateTime? startDate,
    DateTime? endDate,
    SaleType? type,
    String? depotId,
  });

  Future<List<Depot>> fetchDepots();

  Future<String> createSale(GasSale sale);

  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });
}

