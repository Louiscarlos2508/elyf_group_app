import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle Immobilier module settings using SharedPreferences.
class ImmobilierSettingsService {
  final SharedPreferences _prefs;

  ImmobilierSettingsService(this._prefs);

  static const String _keyPrinterAddress = 'immobilier_printer_address';
  static const String _keyPrinterType = 'immobilier_printer_type'; // sunmi, bluetooth, usb, system
  static const String _keyReceiptHeader = 'immobilier_receipt_header';
  static const String _keyReceiptFooter = 'immobilier_receipt_footer';
  static const String _keyShowLogo = 'immobilier_show_logo';

  static const String _keyAutoBillingEnabled = 'immobilier_auto_billing_enabled';
  static const String _keyOverdueGracePeriod = 'immobilier_overdue_grace_period';
  static const String _keyPenaltyRate = 'immobilier_penalty_rate';
  static const String _keyPenaltyType = 'immobilier_penalty_type';

  // --- Printer Settings ---
  // ... (existing code omitted for brevity but I will include it to match target)
  
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

  // --- Receipt Settings ---

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

  // --- Receipt Settings ---

  String get receiptHeader => _prefs.getString(_keyReceiptHeader) ?? 'ELYF IMMOBILIER';

  Future<void> setReceiptHeader(String text) async {
    await _prefs.setString(_keyReceiptHeader, text);
  }

  String get receiptFooter => _prefs.getString(_keyReceiptFooter) ?? 'Merci pour votre confiance !';

  Future<void> setReceiptFooter(String text) async {
    await _prefs.setString(_keyReceiptFooter, text);
  }

  bool get showLogo => _prefs.getBool(_keyShowLogo) ?? true;

  Future<void> setShowLogo(bool show) async {
    await _prefs.setBool(_keyShowLogo, show);
  }
}
