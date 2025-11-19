import '../entities/production.dart';
import '../entities/production_period_config.dart';

/// Production management repository.
abstract class ProductionRepository {
  Future<List<Production>> fetchProductions({
    DateTime? startDate,
    DateTime? endDate,
    int? period,
  });
  Future<Production?> getProduction(String id);
  Future<String> createProduction(Production production);
  Future<int> getMonthProduction(DateTime month);
  Future<double> getAverageProduction();
  Future<ProductionPeriodConfig> getPeriodConfig();
  Future<void> updatePeriodConfig(ProductionPeriodConfig config);
}
