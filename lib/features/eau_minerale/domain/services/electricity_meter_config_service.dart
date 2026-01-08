import '../entities/electricity_meter_type.dart';

/// Service pour gérer la configuration du type de compteur électrique.
/// TODO: Implémenter avec un stockage persistant (Drift/SharedPreferences) quand disponible.
class ElectricityMeterConfigService {
  static final ElectricityMeterConfigService instance =
      ElectricityMeterConfigService._();
  ElectricityMeterConfigService._();

  /// Type de compteur par défaut
  static const ElectricityMeterType _defaultType = ElectricityMeterType.classic;

  /// Type de compteur actuellement configuré (en mémoire pour l'instant)
  ElectricityMeterType _meterType = _defaultType;

  /// Récupère le type de compteur configuré
  Future<ElectricityMeterType> getMeterType() async {
    // TODO: Lire depuis le stockage persistant
    await Future.delayed(const Duration(milliseconds: 100));
    return _meterType;
  }

  /// Définit le type de compteur
  Future<void> setMeterType(ElectricityMeterType type) async {
    // TODO: Sauvegarder dans le stockage persistant
    await Future.delayed(const Duration(milliseconds: 100));
    _meterType = type;
  }

  /// Réinitialise à la valeur par défaut
  Future<void> resetToDefault() async {
    await setMeterType(_defaultType);
  }
}
