import '../../../../features/boutique/domain/entities/sale.dart';
import '../../../../shared/domain/entities/payment_method.dart';
import '../../../../shared.dart';
import '../thermal_receipt_builder.dart';

/// Template pour l'impression de factures de vente sur imprimante thermique.
class SalesReceiptTemplate {
  SalesReceiptTemplate(
    this.sale, {
    this.width = 32,
    this.headerText,
    this.footerText,
    this.showLogo = true,
  });

  final Sale sale;
  final int width;
  final String? headerText;
  final String? footerText;
  final bool showLogo;

  /// Génère le contenu formaté de la facture pour l'impression thermique.
  String generate() {
    final builder = ThermalReceiptBuilder(width: width);

    // Logo / Header
    if (showLogo) {
      builder.center('[ E L Y F ]');
      builder.space();
    }

    builder.header(headerText ?? 'BOUTIQUE ELYF', subtitle: 'ELYF GROUPE - POS');

    // Informations de la vente
    builder.row('Facture N°', sale.number ?? sale.id.substring(0, 8));
    builder.row('Date', _formatDate(sale.date));
    builder.row('Heure', _formatTime(sale.date));
    builder.space();

    if (sale.customerName != null && sale.customerName!.isNotEmpty) {
      builder.row('Client', sale.customerName!);
      builder.space();
    }

    // Articles
    builder.section('Détails Vente');
    
    for (final item in sale.items) {
      final priceDetail = '${item.quantity}x ${CurrencyFormatter.formatFCFA(item.unitPrice)}';
      final totalDetail = CurrencyFormatter.formatFCFA(item.totalPrice);
      builder.itemRow(item.productName, priceDetail, totalDetail);
    }
    builder.separator();

    // Totaux
    builder.total('TOTAL', CurrencyFormatter.formatFCFA(sale.totalAmount));

    if (sale.paymentMethod != null) {
      final method = _getPaymentMethodLabel(sale.paymentMethod!);
      builder.row('Paiement', method);
    }

    builder.row('Montant payé', CurrencyFormatter.formatFCFA(sale.amountPaid));

    if (sale.change > 0) {
      builder.row('Monnaie', CurrencyFormatter.formatFCFA(sale.change));
    }

    // Pied de page
    builder.footer(footerText ?? 'MERCI DE VOTRE VISITE !');

    return builder.toString();
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.both:
        return 'Mixte';
      case PaymentMethod.credit:
        return 'Crédit';
    }
  }
}
