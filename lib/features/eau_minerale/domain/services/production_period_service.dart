import '../entities/production_period_config.dart';

/// Service pour gérer la configuration des périodes de production.
/// Service simple qui peut être remplacé par une implémentation avec stockage plus tard.
class ProductionPeriodService {
  static const _defaultConfig = ProductionPeriodConfig(daysPerPeriod: 10);

  ProductionPeriodConfig _config = _defaultConfig;

  /// Récupère la configuration actuelle des périodes.
  Future<ProductionPeriodConfig> getConfig() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return _config;
  }

  /// Met à jour la configuration des périodes.
  Future<void> updateConfig(ProductionPeriodConfig config) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _config = config;
  }
}
