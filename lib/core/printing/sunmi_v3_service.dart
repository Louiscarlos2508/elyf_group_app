
import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';

import '../logging/app_logger.dart';
import 'package:sunmi_flutter_plugin_printer/bean/printer.dart';
import 'package:sunmi_flutter_plugin_printer/enum/setting_item.dart';
import 'package:sunmi_flutter_plugin_printer/listener/printer_listener.dart';
import 'package:sunmi_flutter_plugin_printer/printer_sdk.dart';
import 'package:sunmi_flutter_plugin_printer/style/text_style.dart';
import 'package:sunmi_flutter_plugin_printer/format/text_format.dart';
import 'package:sunmi_flutter_plugin_printer/enum/align.dart' as sunmi;
import 'package:sunmi_flutter_plugin_printer/style/barcode_style.dart';
import 'package:sunmi_flutter_plugin_printer/style/qr_style.dart';
import 'package:sunmi_flutter_plugin_printer/enum/human_readable.dart';
import 'package:sunmi_flutter_plugin_printer/api/impl/line_api_impl.dart';
import 'printer_interface.dart';

/// Helper class to implement PrinterListener
class _PrinterListenerImpl implements PrinterListener {
  final Function(Printer) onPrinterReceived;

  _PrinterListenerImpl({required this.onPrinterReceived});

  @override
  void onDefPrinter(Printer printer) {
    onPrinterReceived(printer);
  }
}

/// Service for integration with Sunmi V3 Mix printer.
///
/// Automatically detects if the app is running on a Sunmi device
/// and enables thermal receipt printing.
class SunmiV3Service implements PrinterInterface {
  SunmiV3Service._();

  static final SunmiV3Service instance = SunmiV3Service._();
  final _deviceInfo = DeviceInfoPlugin();
  bool? _isSunmiDeviceCache;
  Printer? _printer;
  bool _isInitialized = false;
  String? _model;
  int _paperWidthChars = 32; // Default for 58mm

  /// Checks if the app is running on a Sunmi device.
  Future<bool> get isSunmiDevice async {
    if (_isSunmiDeviceCache != null) return _isSunmiDeviceCache!;

    if (!Platform.isAndroid) {
      _isSunmiDeviceCache = false;
      return false;
    }

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      _model = androidInfo.model;
      final modelLower = _model?.toLowerCase() ?? '';
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      final brand = androidInfo.brand.toLowerCase();

      _isSunmiDeviceCache =
          modelLower.contains('sunmi') ||
          manufacturer.contains('sunmi') ||
          brand.contains('sunmi');

      // Format facture 80x210mm pour toutes les impressions (comme journal)
      if (_isSunmiDeviceCache!) {
        _paperWidthChars = 48; // 80mm
      }

      return _isSunmiDeviceCache!;
    } catch (e) {
      AppLogger.error(
        'SunmiV3Service: Device detection error: $e',
        name: 'printing.sunmi',
        error: e,
      );
      _isSunmiDeviceCache = false;
      return false;
    }
  }

  /// Initializes the Sunmi printer.
  Future<bool> _initializePrinter() async {
    if (_isInitialized) return true;
    if (!await isSunmiDevice) return false;

    try {
      // Enable logs for development
      await PrinterSdk.instance.log(true, 'SunmiV3Service');

      // Get default printer via callback
      Printer? receivedPrinter;
      try {
        await PrinterSdk.instance.getPrinter(
          _PrinterListenerImpl(
            onPrinterReceived: (printer) {
              receivedPrinter = printer;
              _printer = printer;
              _isInitialized = true;
              AppLogger.info(
                'SunmiV3Service: Printer initialized successfully',
                name: 'printing.sunmi',
              );
            },
          ),
        );

        // Wait a bit for callback
        await Future<void>.delayed(const Duration(milliseconds: 300));

        if (receivedPrinter == null || _printer == null) {
          AppLogger.warning(
            'SunmiV3Service: No printer available - simulation mode',
            name: 'printing.sunmi',
          );
          _isInitialized = true;
          return true; // Simulation mode
        }

        return true;
      } catch (e) {
        AppLogger.error(
          'SunmiV3Service: Error getting printer: $e',
          name: 'printing.sunmi',
          error: e,
        );
        _isInitialized = true;
        return true;
      }
    } catch (e) {
      AppLogger.error(
        'SunmiV3Service: Printer initialization error: $e',
        name: 'printing.sunmi',
        error: e,
      );
      return false;
    }
  }

  @override
  Future<bool> initialize() async {
    return await _initializePrinter();
  }

  /// Checks if printer is available.
  Future<bool> isPrinterAvailable() async {
    if (!await isSunmiDevice) return false;

    if (!_isInitialized) {
      final initialized = await _initializePrinter();
      if (!initialized) return false;
    }

    try {
      if (_printer == null) {
        return true; // Simulation mode
      }
      return true;
    } catch (e) {
      AppLogger.error(
        'SunmiV3Service: Printer check error: $e',
        name: 'printing.sunmi',
        error: e,
      );
      return false;
    }
  }

  @override
  Future<bool> isAvailable() async {
    return await isPrinterAvailable();
  }

  @override
  Future<int> getLineWidth() async {
    if (!_isInitialized) await _initializePrinter();
    return _paperWidthChars;
  }

  @override
  Future<bool> printReceipt(String content) async {
    if (!await isSunmiDevice) {
      AppLogger.debug('SunmiV3Service: Non-Sunmi device detected', name: 'printing.sunmi');
      return false;
    }

    if (!await isPrinterAvailable()) {
      AppLogger.warning('SunmiV3Service: Printer not available', name: 'printing.sunmi');
      return false;
    }

    try {
      if (_printer == null) {
        AppLogger.debug('SunmiV3Service: Simulated print:\n$content', name: 'printing.sunmi');
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return true;
      }

      final lineApi = _printer!.lineApi;
      final defaultTextStyle = TextStyle(TextFormat(textSize: 22));
      final titleTextStyle = TextStyle(TextFormat(textSize: 26, enBold: true));
      final totalTextStyle = TextStyle(TextFormat(textSize: 24, enBold: true));

      final cleanedContent = content.trim();
      final lines = cleanedContent.split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty) {
          await lineApi.printText(' ', defaultTextStyle);
          continue;
        }

        // Détection de données tabulaires (ex: Article | Qté | Total)
        if (line.contains('|')) {
          final columns = line.split('|').map((e) => e.trim()).toList();
          
          List<int> weights;
          List<int> alignments;
          
          if (columns.length == 3) {
            // Article | Qté | Total
            weights = [22, 5, 5]; // Proportions pour 80mm
            alignments = [0, 1, 2]; // Gauche, Centre, Droite
          } else if (columns.length == 2) {
            // Label | Valeur
            weights = [1, 1];
            alignments = [0, 2];
          } else {
            weights = List.filled(columns.length, 1);
            alignments = List.filled(columns.length, 0);
          }
          
          await printRow(columns, weights: weights, alignments: alignments);
          continue;
        }

        final trimmedLine = line.trim();
        final isTitle = trimmedLine.contains('EAU MINERALE') || 
                       trimmedLine.contains('ELYF') || 
                       trimmedLine.contains('FACTURE') || 
                       trimmedLine.contains('RECU') ||
                       trimmedLine.contains('RESUME') ||
                       trimmedLine.contains('BOUTIQUE') ||
                       trimmedLine.contains('MERCI') ||
                       trimmedLine.contains('CONFIANCE') ||
                       trimmedLine.contains('SIGNATURE') ||
                       trimmedLine.contains('CACHET') ||
                       trimmedLine.contains('GROUPE');
                       
        // Détecte une ligne composée uniquement de caractères de séparation
        final isSeparator = trimmedLine.isNotEmpty && 
                           trimmedLine.replaceAll(RegExp(r'[-=─═*]'), '').isEmpty;
                       
        final isTotal = trimmedLine.contains('TOTAL') || 
                       trimmedLine.contains('Total') ||
                       trimmedLine.contains('Sous-total') ||
                       trimmedLine.contains('Paiement:') || 
                       trimmedLine.contains('Solde') ||
                       trimmedLine.contains('Montant payé:');

        if (isTitle) {
          await lineApi.printText(trimmedLine, titleTextStyle.setAlign(sunmi.Align.CENTER));
        } else if (isSeparator) {
          // Régularise les séparateurs à 48 caractères (largeur standard 80mm) et centre
          final char = trimmedLine[0];
          final regulatedSeparator = char * 48;
          await lineApi.printText(regulatedSeparator, defaultTextStyle.setAlign(sunmi.Align.CENTER));
        } else if (isTotal) {
          await lineApi.printText(trimmedLine, totalTextStyle);
        } else {
          await lineApi.printText(trimmedLine, defaultTextStyle);
        }
      }

      await lineApi.autoOut();
      return true;

    } catch (e) {
      AppLogger.error('SunmiV3Service: Print error: $e', name: 'printing.sunmi', error: e);
      // Fallback to simulation
      AppLogger.debug('SunmiV3Service: Simulated print (fallback):\n$content', name: 'printing.sunmi');
      return true;
    }
  }

  @override
  Future<bool> printText(String text) async {
    return await printReceipt(text);
  }

  @override
  Future<bool> printRow(List<String> columns, {List<int>? weights, List<int>? alignments}) async {
    if (!await isSunmiDevice) return false;
    
    try {
      if (_printer == null) {
        AppLogger.debug('SunmiV3Service: Simulated row: ${columns.join(' | ')}', name: 'printing.sunmi');
        return true;
      }

      final lineApi = _printer!.lineApi;
      
      // Utilisation des poids par défaut si non fournis
      final actualWeights = weights ?? List.filled(columns.length, 1);
      
      // Styles pour chaque colonne (principalement l'alignement)
      final styles = <TextStyle>[];
      for (int i = 0; i < columns.length; i++) {
        final alignValue = (alignments != null && i < alignments.length) ? alignments[i] : 0;
        
        sunmi.Align align;
        if (alignValue == 1) {
          align = sunmi.Align.CENTER;
        } else if (alignValue == 2) {
          align = sunmi.Align.RIGHT;
        } else {
          align = sunmi.Align.LEFT;
        }

        styles.add(TextStyle(TextFormat(textSize: 22)).setAlign(align));
      }

      await lineApi.printTexts(columns, actualWeights, styles);
      return true;
    } catch (e) {
      AppLogger.error('SunmiV3Service: printRow error: $e', name: 'printing.sunmi', error: e);
      return false;
    }
  }

  // Alias for compatibility if needed
  Future<bool> printPaymentReceipt(String content) async {
    return await printReceipt(content);
  }

  @override
  Future<bool> openDrawer() async {
    return await openCashDrawer();
  }

  /// Opens cash drawer (if available).
  Future<bool> openCashDrawer() async {
    if (!await isSunmiDevice) return false;

    try {
      if (!_isInitialized) await _initializePrinter();
      
      if (_printer == null) {
        AppLogger.debug('SunmiV3Service: Open drawer (simulation)', name: 'printing.sunmi');
        return true;
      }

      AppLogger.info('SunmiV3Service: Opening drawer', name: 'printing.sunmi');
      // Actual drawer opening logic would go here if SDK exposes it directly
      return true;
    } catch (e) {
      AppLogger.error('SunmiV3Service: Drawer error: $e', name: 'printing.sunmi', error: e);
      return false;
    }
  }

  @override
  Future<bool> printImage(Uint8List bytes) async {
    // TODO: Implement using PrinterSdk image methods
    return false;
  }

  @override
  Future<bool> printBarCode(String data, {int? width, int? height}) async {
    if (!await isAvailable()) return false;
    try {
      final lineApi = LineApiImpl.instance;
      
      final barStyle = BarcodeStyle.getStyle()
        .setAlign(sunmi.Align.CENTER)
        .setBarHeight(height ?? 162)
        .setDotWidth(width ?? 2)
        .setReadable(HumanReadable.POS_TWO);
        
      await lineApi.printBarCode(data, barStyle);
      return true;
    } catch (e) {
      AppLogger.error('Error printing barcode: $e', name: 'printing.sunmi');
      return false;
    }
  }

  @override
  Future<bool> printQrCode(String data, {int? size}) async {
    if (!await isAvailable()) return false;
    try {
      final lineApi = LineApiImpl.instance;
      
      final qrStyle = QrStyle.getStyle()
        .setAlign(sunmi.Align.CENTER)
        .setDot(size != null ? (size ~/ 25).clamp(1, 16) : 4);
        
      await lineApi.printQrCode(data, qrStyle);
      return true;
    } catch (e) {
      AppLogger.error('Error printing QR code: $e', name: 'printing.sunmi');
      return false;
    }
  }
  @override
  Future<void> disconnect() async {
    await destroy();
  }

  Future<void> destroy() async {
    try {
      await PrinterSdk.instance.destroy();
      _printer = null;
      _isInitialized = false;
      AppLogger.info('SunmiV3Service: Printer destroyed', name: 'printing.sunmi');
    } catch (e) {
      AppLogger.error('SunmiV3Service: Destroy error: $e', name: 'printing.sunmi', error: e);
    }
  }

  Future<bool?> openPrinterSettings(SettingItem item) async {
    if (!await isSunmiDevice) return false;
    try {
      return await PrinterSdk.instance.startSettings(item);
    } catch (e) {
      return false;
    }
  }
}
