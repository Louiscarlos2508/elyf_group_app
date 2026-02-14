
import 'package:shared_preferences/shared_preferences.dart';
import '../entities/immobilier_settings.dart';
import '../repositories/immobilier_settings_repository.dart';

/// Service to handle Immobilier module settings using SharedPreferences and Repository sync.
class ImmobilierSettingsService {
  final SharedPreferences _prefs;
  final ImmobilierSettingsRepository? _repository;
  final String? _enterpriseId;

  ImmobilierSettingsService(this._prefs, [this._repository, this._enterpriseId]) {
    _initSync();
  }

  void _initSync() {
    if (_repository != null && _enterpriseId != null) {
      _repository!.watchSettings(_enterpriseId!).listen((settings) {
        if (settings != null) {
          _updateLocalFromSynced(settings);
        }
      });
    }
  }

  void _updateLocalFromSynced(ImmobilierSettings settings) {
    _prefs.setString(_keyReceiptHeader, settings.receiptHeader);
    _prefs.setString(_keyReceiptFooter, settings.receiptFooter);
    _prefs.setBool(_keyShowLogo, settings.showLogo);
    _prefs.setInt(_keyOverdueGracePeriod, settings.overdueGracePeriod);
    _prefs.setBool(_keyAutoBillingEnabled, settings.autoBillingEnabled);
  }

  static const String _keyPrinterAddress = 'immobilier_printer_address';
  static const String _keyPrinterType = 'immobilier_printer_type'; // sunmi, bluetooth, usb, system
  static const String _keyReceiptHeader = 'immobilier_receipt_header';
  static const String _keyReceiptFooter = 'immobilier_receipt_footer';
  static const String _keyShowLogo = 'immobilier_show_logo';
  static const String _keyOverdueGracePeriod = 'immobilier_overdue_grace_period';
  static const String _keyAutoBillingEnabled = 'immobilier_auto_billing_enabled';

  // --- Printer Settings (Local Only) ---

  String? get printerAddress => _prefs.getString(_keyPrinterAddress);

  Future<void> setPrinterAddress(String? address) async {
    if (address == null) {
      await _prefs.remove(_keyPrinterAddress);
    } else {
      await _prefs.setString(_keyPrinterAddress, address);
    }
  }

  String get printerType => _prefs.getString(_keyPrinterType) ?? 'system';

  Future<void> setPrinterType(String type) async {
    await _prefs.setString(_keyPrinterType, type);
  }

  // --- Receipt Settings (Synced) ---

  String get receiptHeader => _prefs.getString(_keyReceiptHeader) ?? 'ELYF IMMOBILIER';

  Future<void> setReceiptHeader(String text) async {
    await _prefs.setString(_keyReceiptHeader, text);
    if (_repository != null && _enterpriseId != null) {
      final current = await _repository!.getSettings(_enterpriseId!) ?? ImmobilierSettings(enterpriseId: _enterpriseId!);
      await _repository!.saveSettings(current.copyWith(receiptHeader: text));
    }
  }

  String get receiptFooter => _prefs.getString(_keyReceiptFooter) ?? 'Merci pour votre confiance !';

  Future<void> setReceiptFooter(String text) async {
    await _prefs.setString(_keyReceiptFooter, text);
    if (_repository != null && _enterpriseId != null) {
      final current = await _repository!.getSettings(_enterpriseId!) ?? ImmobilierSettings(enterpriseId: _enterpriseId!);
      await _repository!.saveSettings(current.copyWith(receiptFooter: text));
    }
  }

  bool get showLogo => _prefs.getBool(_keyShowLogo) ?? true;

  Future<void> setShowLogo(bool show) async {
    await _prefs.setBool(_keyShowLogo, show);
    if (_repository != null && _enterpriseId != null) {
      final current = await _repository!.getSettings(_enterpriseId!) ?? ImmobilierSettings(enterpriseId: _enterpriseId!);
      await _repository!.saveSettings(current.copyWith(showLogo: show));
    }
  }

  int get overdueGracePeriod => _prefs.getInt(_keyOverdueGracePeriod) ?? 5;

  Future<void> setOverdueGracePeriod(int days) async {
    await _prefs.setInt(_keyOverdueGracePeriod, days);
    if (_repository != null && _enterpriseId != null) {
      final current = await _repository!.getSettings(_enterpriseId!) ?? ImmobilierSettings(enterpriseId: _enterpriseId!);
      await _repository!.saveSettings(current.copyWith(overdueGracePeriod: days));
    }
  }

  bool get autoBillingEnabled => _prefs.getBool(_keyAutoBillingEnabled) ?? true;

  Future<void> setAutoBillingEnabled(bool enabled) async {
    await _prefs.setBool(_keyAutoBillingEnabled, enabled);
    if (_repository != null && _enterpriseId != null) {
      final current = await _repository!.getSettings(_enterpriseId!) ?? ImmobilierSettings(enterpriseId: _enterpriseId!);
      await _repository!.saveSettings(current.copyWith(autoBillingEnabled: enabled));
    }
  }
}
