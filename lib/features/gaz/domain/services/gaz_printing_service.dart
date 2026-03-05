import 'package:flutter/material.dart';
import '../../../../core/printing/printer_interface.dart';
import '../../../../core/printing/thermal_receipt_builder.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import '../../domain/entities/gas_sale.dart';
// import '../services/gaz_session_calculation_service.dart'; // Removed during session cleanup

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
    try {
      final width = await printerService.getLineWidth();
      final builder = ThermalReceiptBuilder(width: width);

      // Header
      builder.header(enterpriseName?.toUpperCase() ?? 'ELYF GROUP - GAZ', subtitle: 'RECU DE VENTE');
      
      builder.row('Date', _formatDate(sale.saleDate));
      builder.row('No Ticket', sale.id.split('-').last.toUpperCase());
      builder.row('Type Vente', sale.saleType.label);
      builder.space();

      // Client
      if (sale.customerName != null || sale.wholesalerName != null) {
        builder.row('Client', sale.wholesalerName ?? sale.customerName ?? 'Client Divers');
        builder.space();
      }

      // Items
      builder.section('Détail Achat');
      
      final priceDetail = '${sale.quantity}x ${sale.unitPrice.toStringAsFixed(0)}';
      final totalDetail = '${sale.totalAmount.toStringAsFixed(0)} FCFA';
      builder.itemRow(cylinderLabel ?? 'Bouteille Gaz', priceDetail, totalDetail);
      builder.row('Transaction', sale.dealType.label);
      builder.separator();
      
      // Total
      builder.total('TOTAL', '${sale.totalAmount.toStringAsFixed(0)} FCFA');
      builder.row('Paiement', sale.paymentMethod.label);
      
      builder.space();
      builder.footer('Merci de votre confiance !');

      return await printerService.printText(builder.toString());
    } catch (e) {
      debugPrint('GazPrintingService: Error printing receipt: $e');
      return false;
    }
  }

  // printDailySummary was removed during session infrastructure cleanup.
  // It can be re-implemented later using a non-session based approach if needed.

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
