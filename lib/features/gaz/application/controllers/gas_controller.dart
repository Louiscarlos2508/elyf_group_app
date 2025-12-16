import '../../domain/entities/cylinder.dart';
import '../../domain/entities/depot.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/repositories/gas_repository.dart';

class GasController {
  GasController(this._repository);

  final GasRepository _repository;

  Future<GasState> fetchState() async {
    final cylinders = await _repository.fetchCylinders();
    final sales = await _repository.fetchSales();
    final depots = await _repository.fetchDepots();
    final statistics = await _repository.getStatistics();
    return GasState(
      cylinders: cylinders,
      sales: sales,
      depots: depots,
      statistics: statistics,
    );
  }

  Future<String> createSale(GasSale sale) async {
    return await _repository.createSale(sale);
  }

  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _repository.getStatistics(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

class GasState {
  const GasState({
    required this.cylinders,
    required this.sales,
    required this.depots,
    required this.statistics,
  });

  final List<Cylinder> cylinders;
  final List<GasSale> sales;
  final List<Depot> depots;
  final Map<String, dynamic> statistics;
}

