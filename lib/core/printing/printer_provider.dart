
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'printer_interface.dart';
import 'sunmi_v3_service.dart';
import 'thermal_printer_service.dart';
import 'system_printer_service.dart';

/// Provider qui retourne l'instance d'imprimante active selon les réglages
final activePrinterProvider = Provider<PrinterInterface>((ref) {
  final settings = ref.watch(boutiqueSettingsServiceProvider);
  final type = settings.printerType;

  switch (type) {
    case 'sunmi':
      return SunmiV3Service.instance;
    case 'bluetooth':
      return ThermalPrinterService();
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
