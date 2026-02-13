
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle Boutique module settings using SharedPreferences.
class BoutiqueSettingsService {
  final SharedPreferences _prefs;

  BoutiqueSettingsService(this._prefs);

  static const String _keyPrinterAddress = 'boutique_printer_address';
  static const String _keyPrinterType = 'boutique_printer_type'; // sunmi, bluetooth, usb
  static const String _keyReceiptHeader = 'boutique_receipt_header';
  static const String _keyReceiptFooter = 'boutique_receipt_footer';
  static const String _keyShowLogo = 'boutique_show_logo';
  static const String _keyLowStockThreshold = 'boutique_low_stock_threshold';
  static const String _keyPaymentMethods = 'boutique_payment_methods'; // Comma separated

  // --- Printer Settings ---

  String? get printerAddress => _prefs.getString(_keyPrinterAddress);

  Future<void> setPrinterAddress(String? address) async {
    if (address == null) {
      await _prefs.remove(_keyPrinterAddress);
    } else {
      await _prefs.setString(_keyPrinterAddress, address);
    }
  }

  String get printerType => _prefs.getString(_keyPrinterType) ?? 'sunmi';

  Future<void> setPrinterType(String type) async {
    await _prefs.setString(_keyPrinterType, type);
  }

  // Generic Printer Params
  static const String _keyPrinterConnection = 'boutique_printer_connection';
  
  String? get printerConnection => _prefs.getString(_keyPrinterConnection);
  
  Future<void> setPrinterConnection(String? connection) async {
    if (connection == null) {
      await _prefs.remove(_keyPrinterConnection);
    } else {
      await _prefs.setString(_keyPrinterConnection, connection);
    }
  }

  // --- Receipt Settings ---

  String get receiptHeader => _prefs.getString(_keyReceiptHeader) ?? 'ELYF GROUP';

  Future<void> setReceiptHeader(String text) async {
    await _prefs.setString(_keyReceiptHeader, text);
  }

  String get receiptFooter => _prefs.getString(_keyReceiptFooter) ?? 'Merci de votre visite!';

  Future<void> setReceiptFooter(String text) async {
    await _prefs.setString(_keyReceiptFooter, text);
  }

  bool get showLogo => _prefs.getBool(_keyShowLogo) ?? true;

  Future<void> setShowLogo(bool show) async {
    await _prefs.setBool(_keyShowLogo, show);
  }

  // --- Alert Settings ---

  int get lowStockThreshold => _prefs.getInt(_keyLowStockThreshold) ?? 5;

  Future<void> setLowStockThreshold(int threshold) async {
    await _prefs.setInt(_keyLowStockThreshold, threshold);
  }

  // --- Payment Methods ---

  List<String> get enabledPaymentMethods {
    final String? stored = _prefs.getString(_keyPaymentMethods);
    if (stored == null) {
      return ['cash', 'mobile_money', 'card']; // Default all enabled
    }
    return stored.split(',');
  }

  Future<void> setEnabledPaymentMethods(List<String> methods) async {
    await _prefs.setString(_keyPaymentMethods, methods.join(','));
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
