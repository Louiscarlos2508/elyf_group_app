import 'package:flutter/material.dart';
import '../../../../core/printing/printer_interface.dart';
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
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('--------------------------------');
      final name = enterpriseName?.toUpperCase() ?? 'ELYF GROUP - GAZ';
      buffer.writeln(name);
      buffer.writeln('--------------------------------');
      buffer.writeln('RECU DE VENTE');
      buffer.writeln('Date: ${_formatDate(sale.saleDate)}');
      buffer.writeln('No: ${sale.id.split('-').last}');
      buffer.writeln('Type: ${sale.saleType.label}');
      buffer.writeln('--------------------------------');

      // Client
      if (sale.customerName != null) {
        buffer.writeln('Client: ${sale.customerName}');
      }
      if (sale.wholesalerName != null) {
        buffer.writeln('Grossiste: ${sale.wholesalerName}');
      }
      buffer.writeln('--------------------------------');

      // Items
      buffer.writeln('Article | ${cylinderLabel ?? 'Bouteille'}');
      buffer.writeln('Transaction | ${sale.dealType.label}');
      buffer.writeln('Qté | ${sale.quantity}');
      buffer.writeln('Prix Unitaire | ${sale.unitPrice.toStringAsFixed(0)} FCFA');
      buffer.writeln('--------------------------------');
      
      // Total
      buffer.writeln('TOTAL | ${sale.totalAmount.toStringAsFixed(0)} FCFA');
      buffer.writeln('Mode: ${sale.paymentMethod.label}');
      buffer.writeln('--------------------------------');
      buffer.writeln('Merci de votre confiance !');
      buffer.writeln('\n\n\n'); // Espace pour la découpe

      return await printerService.printText(buffer.toString());
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
