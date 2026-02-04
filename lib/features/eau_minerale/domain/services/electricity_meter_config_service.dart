import 'package:shared_preferences/shared_preferences.dart';
import '../entities/electricity_meter_type.dart';

/// Service pour gérer la configuration de l'électricité (type de compteur et taux).
class ElectricityMeterConfigService {
  static final ElectricityMeterConfigService instance =
      ElectricityMeterConfigService._();
  ElectricityMeterConfigService._();

  static const String _typeKey = 'electricity_meter_type';
  static const String _rateKey = 'electricity_rate';
  
  /// Type de compteur par défaut
  static const ElectricityMeterType _defaultType = ElectricityMeterType.classic;
  static const double _defaultRate = 125.0; // CFA par kWh

  /// Récupère le type de compteur configuré
  Future<ElectricityMeterType> getMeterType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeIndex = prefs.getInt(_typeKey);
    if (typeIndex != null && typeIndex >= 0 && typeIndex < ElectricityMeterType.values.length) {
      return ElectricityMeterType.values[typeIndex];
    }
    return _defaultType;
  }

  /// Définit le type de compteur
  Future<void> setMeterType(ElectricityMeterType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_typeKey, type.index);
  }

  /// Récupère le taux d'électricité (CFA/kWh)
  Future<double> getElectricityRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_rateKey) ?? _defaultRate;
  }

  /// Définit le taux d'électricité
  Future<void> setElectricityRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rateKey, rate);
  }

  /// Réinitialise à la valeur par défaut
  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_typeKey);
    await prefs.remove(_rateKey);
  }
}
