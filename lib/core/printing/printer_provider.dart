
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'printer_interface.dart';
import 'sunmi_v3_service.dart';
import 'thermal_printer_service.dart';
import 'system_printer_service.dart';

/// Simple configuration for printer
class PrinterConfig {
  final String type;
  final String? address;

  const PrinterConfig({
    required this.type,
    this.address,
  });
}

/// Provider for the printer configuration.
/// Modules should override this provider in their respective ProviderScope
/// or it will default to a 'system' printer.
final printerConfigProvider = Provider<PrinterConfig>((ref) {
  return const PrinterConfig(type: 'system');
});

/// Provider qui retourne l'instance d'imprimante active selon les réglages
final activePrinterProvider = Provider<PrinterInterface>((ref) {
  final config = ref.watch(printerConfigProvider);
  final type = config.type;

  switch (type) {
    case 'sunmi':
      return SunmiV3Service.instance;
    case 'bluetooth':
      final service = ThermalPrinterService();
      // If address is provided, the service should eventually handle it.
      // For now, ThermalPrinterService is a singleton that manages its own connection.
      return service;
    case 'system':
    default:
      return SystemPrinterService();
  }
});

/// Provider pour vérifier si une imprimante est configurée/disponible
final isPrinterAvailableProvider = FutureProvider<bool>((ref) async {
  final printer = ref.watch(activePrinterProvider);
  return await printer.isAvailable();
});
