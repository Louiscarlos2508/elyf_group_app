
import 'package:shared_preferences/shared_preferences.dart';
import '../entities/boutique_settings.dart';
import '../repositories/boutique_settings_repository.dart';

/// Service to handle Boutique module settings using SharedPreferences and Repository sync.
class BoutiqueSettingsService {
  final SharedPreferences _prefs;
  final BoutiqueSettingsRepository? _repository;
  final String? _enterpriseId;

  BoutiqueSettingsService(this._prefs, [this._repository, this._enterpriseId]) {
    _initSync();
  }

  void _initSync() {
    if (_repository != null && _enterpriseId != null) {
      _repository.watchSettings(_enterpriseId).listen((settings) {
        if (settings != null) {
          _updateLocalFromSynced(settings);
        }
      });
    }
  }

  void _updateLocalFromSynced(BoutiqueSettings settings) {
    _prefs.setInt(_keyLowStockThreshold, settings.lowStockThreshold);
    _prefs.setString(_keyPaymentMethods, settings.enabledPaymentMethods.join(','));
  }

  static const String _keyLowStockThreshold = 'boutique_low_stock_threshold';
  static const String _keyPaymentMethods = 'boutique_payment_methods'; // Comma separated

  // --- Alert Settings (Synced) ---

  int get lowStockThreshold => _prefs.getInt(_keyLowStockThreshold) ?? 5;

  Future<void> setLowStockThreshold(int threshold) async {
    await _prefs.setInt(_keyLowStockThreshold, threshold);
    if (_repository != null && _enterpriseId != null) {
      final current = await _repository.getSettings(_enterpriseId) ?? BoutiqueSettings(enterpriseId: _enterpriseId);
      await _repository.saveSettings(current.copyWith(lowStockThreshold: threshold));
    }
  }

  // --- Payment Methods (Synced) ---

  List<String> get enabledPaymentMethods {
    final String? stored = _prefs.getString(_keyPaymentMethods);
    if (stored == null) {
      return ['cash', 'mobile_money', 'card']; // Default all enabled
    }
    return stored.split(',');
  }

  Future<void> setEnabledPaymentMethods(List<String> methods) async {
    await _prefs.setString(_keyPaymentMethods, methods.join(','));
    if (_repository != null && _enterpriseId != null) {
      final current = await _repository.getSettings(_enterpriseId) ?? BoutiqueSettings(enterpriseId: _enterpriseId);
      await _repository.saveSettings(current.copyWith(enabledPaymentMethods: methods));
    }
  }

  bool isPaymentMethodEnabled(String methodId) {
    return enabledPaymentMethods.contains(methodId);
  }

  Future<void> togglePaymentMethod(String methodId, bool isEnabled) async {
    final methods = enabledPaymentMethods.toSet();
    if (isEnabled) {
      methods.add(methodId);
    } else {
      methods.remove(methodId);
    }
    await setEnabledPaymentMethods(methods.toList());
  }
}
