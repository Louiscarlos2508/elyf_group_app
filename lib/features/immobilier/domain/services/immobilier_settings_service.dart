import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle Immobilier module settings using SharedPreferences.
class ImmobilierSettingsService {
  final SharedPreferences _prefs;

  ImmobilierSettingsService(this._prefs);

  static const String _keyAutoBillingEnabled = 'immobilier_auto_billing_enabled';
  static const String _keyOverdueGracePeriod = 'immobilier_overdue_grace_period';
  static const String _keyPenaltyRate = 'immobilier_penalty_rate';
  static const String _keyPenaltyType = 'immobilier_penalty_type';

  // --- Billing Settings ---
  
  bool get autoBillingEnabled => _prefs.getBool(_keyAutoBillingEnabled) ?? true;
  
  Future<void> setAutoBillingEnabled(bool enabled) async {
    await _prefs.setBool(_keyAutoBillingEnabled, enabled);
  }
  
  int get overdueGracePeriod => _prefs.getInt(_keyOverdueGracePeriod) ?? 5;
  
  Future<void> setOverdueGracePeriod(int days) async {
    await _prefs.setInt(_keyOverdueGracePeriod, days);
  }

  double get penaltyRate => _prefs.getDouble(_keyPenaltyRate) ?? 0.0;

  Future<void> setPenaltyRate(double rate) async {
    await _prefs.setDouble(_keyPenaltyRate, rate);
  }

  String get penaltyType => _prefs.getString(_keyPenaltyType) ?? 'fixed';

  Future<void> setPenaltyType(String type) async {
    await _prefs.setString(_keyPenaltyType, type);
  }
}
