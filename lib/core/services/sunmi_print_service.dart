import '../printing/sunmi_v3_service.dart';
import '../utils/formatters.dart';
import '../../features/tour/data/models/livraison_entry.dart';
import '../../features/tour/data/models/bilan_tour.dart';
import '../../features/gaz/domain/entities/gas_sale.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

/// Service d'impression Sunmi pour le module Tour.
class SunmiPrintService {
  static final SunmiPrintService instance = SunmiPrintService._();
  SunmiPrintService._();

  final _sunmiV3 = SunmiV3Service.instance;

  Future<bool> isAvailable() async {
    return _sunmiV3.isAvailable();
  }

  /// Imprime un ticket de livraison pour Grossiste
  Future<bool> printDeliveryReceipt({
    required String enterpriseName,
    required String siteName,
    required LivraisonEntry entry,
  }) async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln("   $enterpriseName   ");
    buffer.writeln("DÉPARTEMENT GAZ");
    buffer.writeln("================================");
    buffer.writeln("FACTURE DE LIVRAISON");
    buffer.writeln("Site: $siteName");
    buffer.writeln("Date: ${Formatters.formatDateTime(entry.timestamp)}");
    buffer.writeln("--------------------------------");
    
    // Table
    buffer.writeln("ARTICLE      | QTÉ | TOTAL ");
    buffer.writeln("--------------------------------");
    for (var ligne in entry.lignes) {
      final label = _truncate(ligne.format.label, 12);
      buffer.writeln("$label | ${ligne.quantiteLivree} | ${Formatters.formatCurrency(ligne.sousTotal)}");
    }
    buffer.writeln("--------------------------------");
    
    // Total
    buffer.writeln("TOTAL À PAYER: ${Formatters.formatCurrency(entry.totalMontant)}");
    buffer.writeln("================================");
    buffer.writeln("   MERCI DE VOTRE CONFIANCE   ");
    buffer.writeln("\n\n\n"); // Espace pour déchirement

    return _sunmiV3.printReceipt(buffer.toString());
  }

  /// Imprime le bilan final du tour
  Future<bool> printTourBilan({
    required String driverName,
    required BilanTour bilan,
    required DateTime date,
  }) async {
    final buffer = StringBuffer();
    
    buffer.writeln("   RÉSUMÉ DE TOURNÉE   ");
    buffer.writeln("Gérant: $driverName");
    buffer.writeln("Date: ${Formatters.formatDate(date)}");
    buffer.writeln("================================");
    
    buffer.writeln("Ventes Sites: ${Formatters.formatCurrency(bilan.totalEncaisse)}");
    if (bilan.postClosureCash != 0) {
      buffer.writeln("Post-Tour: ${Formatters.formatCurrency(bilan.postClosureCash)}");
    }
    buffer.writeln("Coût Recharge: -${Formatters.formatCurrency(bilan.coutRecharge)}");
    buffer.writeln("Frais Trajet: -${Formatters.formatCurrency(bilan.totalFrais)}");
    buffer.writeln("--------------------------------");
    buffer.writeln("RÉSULTAT NET: ${Formatters.formatCurrency(bilan.resultatNet)}");
    buffer.writeln("================================");
    
    buffer.writeln("DÉTAIL PAR SITE");
    buffer.writeln("SITE | ENT | SORT | ENCAISS");
    buffer.writeln("--------------------------------");
    for (var site in bilan.siteBreakdowns) {
      final name = site.siteName;
      buffer.writeln(name);
      buffer.writeln("  E:${site.totalEntrees} | S:${site.totalSorties} | ${Formatters.formatCurrency(site.encaissement.toInt())}");
    }

    if (bilan.postClosureLeaks > 0 || bilan.postClosureCash != 0) {
      buffer.writeln("--------------------------------");
      if (bilan.postClosureLeaks > 0) {
        buffer.writeln("FUITES POST-TOUR: ${bilan.postClosureLeaks}");
      }
      if (bilan.postClosureCash != 0) {
        buffer.writeln("PLUS-VALUE POS/FLUX: ${Formatters.formatCurrency(bilan.postClosureCash.toInt())}");
      }
    }
    
    buffer.writeln("================================");
    buffer.writeln("Signature Gérant");
    buffer.writeln("\n\n\n\n");

    return _sunmiV3.printReceipt(buffer.toString());
  }

  /// Imprime un reçu pour un paiement immobilier
  Future<bool> printImmobilierPaymentReceipt({
    required String enterpriseName,
    required String receiptNumber,
    required DateTime paymentDate,
    required double amount,
    required String paymentMethod,
    required String tenantName,
    required String propertyAddress,
    String? period,
  }) async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln("   $enterpriseName   ");
    buffer.writeln("DÉPARTEMENT IMMOBILIER");
    buffer.writeln("================================");
    buffer.writeln("REÇU DE PAIEMENT");
    buffer.writeln("Date: ${Formatters.formatDateTime(paymentDate)}");
    buffer.writeln("N° Reçu: $receiptNumber");
    buffer.writeln("--------------------------------");

    // Client/Locataire
    buffer.writeln("Locataire: $tenantName");
    buffer.writeln("Propriété: $propertyAddress");
    if (period != null) {
      buffer.writeln("Période: $period");
    }
    buffer.writeln("--------------------------------");

    // Total
    buffer.writeln("MONTANT PAYÉ: ${Formatters.formatCurrency(amount.toInt())}");
    buffer.writeln("Mode: $paymentMethod");
    buffer.writeln("================================");
    buffer.writeln("   MERCI DE VOTRE CONFIANCE   ");
    buffer.writeln("\n\n\n");

    return _sunmiV3.printReceipt(buffer.toString());
  }

  /// Imprime un reçu pour une vente de gaz individuelle
  Future<bool> printGasSaleReceipt({
    required String enterpriseName,
    required GasSale sale,
    String? cylinderLabel,
  }) async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln("   $enterpriseName   ");
    buffer.writeln("DÉPARTEMENT GAZ");
    buffer.writeln("================================");
    buffer.writeln("REÇU DE VENTE");
    buffer.writeln("Date: ${Formatters.formatDateTime(sale.saleDate)}");
    buffer.writeln("Ticket: ${sale.id.split('-').last.toUpperCase()}");
    buffer.writeln("--------------------------------");

    // Client
    if (sale.wholesalerName != null || sale.customerName != null) {
      buffer.writeln("Client: ${sale.wholesalerName ?? sale.customerName}");
      buffer.writeln("--------------------------------");
    }

    // Detail
    buffer.writeln("ARTICLE      | QTÉ | TOTAL ");
    buffer.writeln("--------------------------------");
    
    final label = _truncate(cylinderLabel ?? "Gaz BTL", 12);
    buffer.writeln("$label | ${sale.quantity} | ${Formatters.formatCurrency(sale.totalAmount)}");
    buffer.writeln("Transaction: ${sale.dealType.label}");
    buffer.writeln("--------------------------------");

    // Total
    buffer.writeln("TOTAL PAYÉ: ${Formatters.formatCurrency(sale.totalAmount)}");
    buffer.writeln("Mode: ${sale.paymentMethod.label}");
    buffer.writeln("================================");
    buffer.writeln("   MERCI DE VOTRE CONFIANCE   ");
    buffer.writeln("\n\n\n");

    return _sunmiV3.printReceipt(buffer.toString());
  }

  /// Imprime un reçu pour une vente groupée (Grossiste)
  Future<bool> printGasBatchSaleReceipt({
    required String enterpriseName,
    required List<GasSale> sales,
  }) async {
    if (sales.isEmpty) return false;
    final buffer = StringBuffer();
    final firstSale = sales.first;
    
    // Header
    buffer.writeln("   $enterpriseName   ");
    buffer.writeln("DÉPARTEMENT GAZ");
    buffer.writeln("================================");
    buffer.writeln("FACTURE DE VENTE GROSSISTE");
    buffer.writeln("Date: ${Formatters.formatDateTime(firstSale.saleDate)}");
    if (firstSale.wholesalerName != null) {
      buffer.writeln("Grossiste: ${firstSale.wholesalerName}");
    }
    buffer.writeln("--------------------------------");

    // Table
    buffer.writeln("ARTICLE      | QTÉ | TOTAL ");
    buffer.writeln("--------------------------------");
    
    double totalGeneral = 0;
    for (var sale in sales) {
      totalGeneral += sale.totalAmount;
      // Note: cylinderLabel is not easily available in batch, using generic or assuming weight
      // If we had the cylinder type we could be more precise.
      final label = _truncate("Gaz BTL", 12);
      buffer.writeln("$label | ${sale.quantity} | ${Formatters.formatCurrency(sale.totalAmount)}");
    }
    buffer.writeln("--------------------------------");

    // Total
    buffer.writeln("TOTAL GÉNÉRAL: ${Formatters.formatCurrency(totalGeneral)}");
    buffer.writeln("Mode: ${firstSale.paymentMethod.label}");
    buffer.writeln("================================");
    buffer.writeln("   MERCI DE VOTRE CONFIANCE   ");
    buffer.writeln("\n\n\n");

    return _sunmiV3.printReceipt(buffer.toString());
  }

  String _truncate(String text, int length) {
    if (text.length <= length) return text.padRight(length);
    return "${text.substring(0, length - 1)}.";
  }
}
