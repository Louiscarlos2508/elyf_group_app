import '../../domain/entities/production.dart';
import '../../domain/entities/production_period_config.dart';
import '../../domain/repositories/production_repository.dart';

class ProductionController {
  ProductionController(this._repository);

  final ProductionRepository _repository;

  Future<ProductionState> fetchTodayProductions() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final productions = await _repository.fetchProductions(
      startDate: start,
      endDate: end,
    );
    return ProductionState(productions: productions);
  }

  Future<ProductionState> fetchAllProductions() async {
    final productions = await _repository.fetchProductions();
    return ProductionState(productions: productions);
  }

  Future<String> createProduction(Production production) async {
    return await _repository.createProduction(production);
  }

  Future<ProductionPeriodConfig> getPeriodConfig() async {
    return await _repository.getPeriodConfig();
  }

  Future<void> updatePeriodConfig(ProductionPeriodConfig config) async {
    return await _repository.updatePeriodConfig(config);
  }
}

class ProductionState {
  const ProductionState({required this.productions});

  final List<Production> productions;

  int get totalQuantity =>
      productions.fold(0, (value, prod) => value + prod.quantity);
}
