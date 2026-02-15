import 'package:flutter/material.dart';
import '../../../../core/printing/thermal_printer_service.dart';
import '../../domain/entities/gas_sale.dart';
import '../services/gaz_calculation_service.dart';

/// Service spécialisé pour le formatage et l'impression des reçus Gaz.
class GazPrintingService {
  const GazPrintingService({required this.printerService});

  final ThermalPrinterService printerService;

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
      buffer.writeln(enterpriseName?.toUpperCase() ?? 'ELYF GROUP - GAZ');
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
      buffer.writeln('Article: ${cylinderLabel ?? 'Bouteille'}');
      buffer.writeln('Transaction: ${sale.dealType.label}');
      buffer.writeln('Qté: ${sale.quantity}');
      buffer.writeln('Prix Unitaire: ${sale.unitPrice.toStringAsFixed(0)} FCFA');
      buffer.writeln('--------------------------------');
      
      // Total
      buffer.writeln('TOTAL: ${sale.totalAmount.toStringAsFixed(0)} FCFA');
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

  /// Imprime un résumé journalier (Z-Report).
  Future<bool> printDailySummary({
    required ReconciliationMetrics metrics,
    String? enterpriseName,
  }) async {
    try {
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('--------------------------------');
      buffer.writeln(enterpriseName?.toUpperCase() ?? 'ELYF GROUP - GAZ');
      buffer.writeln('--------------------------------');
      buffer.writeln('RESUME DE LA JOURNEE (Z)');
      buffer.writeln('Date: ${_formatDate(metrics.date)}');
      buffer.writeln('--------------------------------');

      // Totals
      buffer.writeln('VENTES TOTales : ${metrics.totalSales.toStringAsFixed(0)} FCFA');
      buffer.writeln('DEPENSES      : ${metrics.totalExpenses.toStringAsFixed(0)} FCFA');
      buffer.writeln('CASH THEORIQUE: ${metrics.theoreticalCash.toStringAsFixed(0)} FCFA');
      buffer.writeln('--------------------------------');

      // Payment Methods
      buffer.writeln('PAR MODE DE PAIEMENT:');
      metrics.salesByPaymentMethod.forEach((method, amount) {
        if (amount > 0) {
          buffer.writeln('${method.label.padRight(12)}: ${amount.toStringAsFixed(0)} FCFA');
        }
      });
      buffer.writeln('--------------------------------');

      // Format Breakdown
      buffer.writeln('PAR FORMAT DE BOUTEILLE:');
      metrics.salesByCylinderWeight.forEach((weight, count) {
        if (count > 0) {
          buffer.writeln('${weight}kg'.padRight(12) + ': $count unités');
        }
      });
      buffer.writeln('--------------------------------');
      
      buffer.writeln('ELYF GROUP - Gestion Inteligente');
      buffer.writeln('\n\n\n');

      return await printerService.printText(buffer.toString());
    } catch (e) {
      debugPrint('GazPrintingService: Error printing summary: $e');
      return false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
