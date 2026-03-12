import '../../../../core/printing/printer_interface.dart';
import '../../../../core/services/sunmi_print_service.dart';
import '../../domain/entities/gas_sale.dart';

/// Service spécialisé pour le formatage et l'impression des reçus Gaz.
class GazPrintingService {
  const GazPrintingService({required this.printerService});

  final PrinterInterface printerService;

  /// Imprime un reçu pour une vente de gaz.
  Future<bool> printSaleReceipt({
    required GasSale sale,
    String? cylinderLabel,
    String? enterpriseName,
  }) async {
    // Delegate to unified Sunmi printing service for consistent template
    return SunmiPrintService.instance.printGasSaleReceipt(
      enterpriseName: enterpriseName ?? 'ELYF GROUP - GAZ',
      sale: sale,
      cylinderLabel: cylinderLabel,
    );
  }

  /// Imprime un reçu pour une vente de gaz groupée (plusieurs poids).
  Future<bool> printBatchSaleReceipt({
    required List<GasSale> sales,
    String? enterpriseName,
  }) async {
    if (sales.isEmpty) return false;
    // Delegate to unified Sunmi printing service
    return SunmiPrintService.instance.printGasBatchSaleReceipt(
      enterpriseName: enterpriseName ?? 'ELYF GROUP - GAZ',
      sales: sales,
    );
  }

}
