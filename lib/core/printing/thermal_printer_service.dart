
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../logging/app_logger.dart';
import 'printer_interface.dart';

class ThermalPrinterService implements PrinterInterface {
  ThermalPrinterService._();

  static final ThermalPrinterService _instance = ThermalPrinterService._();
  factory ThermalPrinterService() => _instance;

  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  
  // Current connection
  BluetoothConnection? _connection;
  bool _isConnected = false;
  
  // Default paper size (58mm or 80mm)
  final PaperSize _paperSize = PaperSize.mm58;
  CapabilityProfile? _profile;

  @override
  Future<bool> initialize() async {
    try {
      // Load default profile
      _profile = await CapabilityProfile.load();
      
      // Check initial state
      if (_connection != null && _connection!.isConnected) {
        _isConnected = true;
      }
      
      return true;
    } catch (e) {
      AppLogger.error('Error initializing ThermalPrinterService: $e', name: 'printing.thermal', error: e);
      return false;
    }
  }


  /// Connect to a specific Bluetooth device
  Future<bool> connectBluetooth(BluetoothDevice device) async {
    return connectToAddress(device.address);
  }

  /// Connect directly by address
  Future<bool> connectToAddress(String address) async {
    try {
      // Disconnect existing
      await disconnect();
      
      // Connect
      _connection = await BluetoothConnection.toAddress(address);
      _isConnected = _connection?.isConnected ?? false;
      
      if (_isConnected) {
        AppLogger.info('Connected to $address', name: 'printing.thermal');
      }

      return _isConnected;
    } catch (e) {
      AppLogger.error('Error connecting to $address: $e', name: 'printing.thermal', error: e);
      _isConnected = false;
      return false;
    }
  }

  /// Scan for Bluetooth devices
  Stream<BluetoothDiscoveryResult> scanBluetooth() {
    try {
      return _bluetooth.startDiscovery();
    } catch (e) {
      AppLogger.error('Error starting scan: $e', name: 'printing.thermal', error: e);
      return const Stream.empty();
    }
  }

  /// Get list of bonded (paired) devices
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      return await _bluetooth.getBondedDevices();
    } catch (e) {
      AppLogger.error('Error getting bonded devices: $e', name: 'printing.thermal', error: e);
      return [];
    }
  }

  @override
  Future<bool> isAvailable() async {
    return _isConnected && (_connection?.isConnected ?? false);
  }

  @override
  Future<int> getLineWidth() async {
    return _paperSize == PaperSize.mm58 ? 32 : 48;
  }

  @override
  Future<bool> printText(String text) async {
    return printReceipt(text);
  }

  @override
  Future<bool> printReceipt(String content) async {
    if (!await isAvailable()) return false;
    if (_profile == null) await initialize();

    try {
      final generator = Generator(_paperSize, _profile!);
      List<int> bytes = [];

      // Reset
      bytes += generator.reset();

      // Content parsing
      final lines = content.split('\n');
      for (final line in lines) {
         if (line.trim().isEmpty) {
           bytes += generator.feed(1);
           continue;
         }

         // Simple heuristic for styling based on content
         // Titles
         if (line.contains('ELYF') || line.contains('FACTURE') || line.contains('RECU')) {
           bytes += generator.text(
             line, 
             styles: const PosStyles(
               align: PosAlign.center, 
               bold: true,
               height: PosTextSize.size2,
               width: PosTextSize.size2,
             ),
           );
         } 
         // Totals
         else if (line.contains('TOTAL') || line.contains('PAIEMENT') || line.contains('SOLDE')) {
             bytes += generator.text(
             line, 
             styles: const PosStyles(
               align: PosAlign.right, 
               bold: true,
               height: PosTextSize.size1,
               width: PosTextSize.size1,
             ),
           );
         }
         // Normal
         else {
            bytes += generator.text(line);
         }
      }

      bytes += generator.feed(2);
      bytes += generator.cut();

      // Send to printer
      _connection!.output.add(Uint8List.fromList(bytes));
      await _connection!.output.allSent;

      return true;

    } catch (e) {
      AppLogger.error('Error printing receipt: $e', name: 'printing.thermal', error: e);
      _isConnected = false; // Assume disconnection on write error
      return false;
    }
  }

  @override
  Future<bool> printImage(Uint8List bytes) async {
    // TODO: Implement image printing
    return false;
  }

  @override
  Future<bool> openDrawer() async {
     if (!await isAvailable()) return false;
     try {
       final generator = Generator(_paperSize, _profile!);
       _connection!.output.add(Uint8List.fromList(generator.drawer()));
       await _connection!.output.allSent;
       return true;
     } catch (e) {
       return false;
     }
  }

  @override
  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.close();
      } catch (e) {
        // Ignore errors during close
      }
      _connection = null;
    }
    _isConnected = false;
  }
}
