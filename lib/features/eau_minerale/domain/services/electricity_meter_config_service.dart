import '../entities/eau_minerale_settings.dart';
import '../entities/electricity_meter_type.dart';
import '../repositories/settings_repository.dart';

/// Service pour gérer la configuration de l'électricité (type de compteur et taux).
class ElectricityMeterConfigService {
  ElectricityMeterConfigService({
    required EauMineraleSettingsRepository settingsRepository,
    required String enterpriseId,
  })  : _settingsRepository = settingsRepository,
        _enterpriseId = enterpriseId;

  final EauMineraleSettingsRepository _settingsRepository;
  final String _enterpriseId;

  /// Type de compteur par défaut
  static const ElectricityMeterType _defaultType = ElectricityMeterType.classic;
  static const double _defaultRate = 125.0; // CFA par kWh

  /// Récupère les paramètres complets
  Future<EauMineraleSettings> _getSettings() async {
    final settings = await _settingsRepository.getSettings();
    return settings ?? EauMineraleSettings.defaultSettings(_enterpriseId);
  }

  /// Récupère le type de compteur configuré
  Future<ElectricityMeterType> getMeterType() async {
    final settings = await _getSettings();
    return settings.meterType;
  }

  /// Définit le type de compteur
  Future<void> setMeterType(ElectricityMeterType type) async {
    final current = await _getSettings();
    await _settingsRepository.saveSettings(current.copyWith(
      meterType: type,
      updatedAt: DateTime.now(),
    ));
  }

  /// Récupère le taux d'électricité (CFA/kWh)
  Future<double> getElectricityRate() async {
    final settings = await _getSettings();
    return settings.electricityRate;
  }

  /// Définit le taux d'électricité
  Future<void> setElectricityRate(double rate) async {
    final current = await _getSettings();
    await _settingsRepository.saveSettings(current.copyWith(
      electricityRate: rate,
      updatedAt: DateTime.now(),
    ));
  }

  /// Réinitialise à la valeur par défaut
  Future<void> resetToDefault() async {
    await _settingsRepository.saveSettings(
      EauMineraleSettings.defaultSettings(_enterpriseId).copyWith(
        updatedAt: DateTime.now(),
      ),
    );
  }
}
