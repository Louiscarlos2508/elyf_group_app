import '../../../domain/entities/sale.dart';
import 'invoice_print_helpers.dart';
import '../../../../../core/printing/thermal_receipt_builder.dart';

/// Génère le contenu texte pour l'imprimante thermique (vente).
String generateSaleReceipt(Sale sale) {
  final builder = ThermalReceiptBuilder(width: 32);

  // Entête moderne et centré
  builder.header('EAU MINERALE ELYF', subtitle: 'GROUPE APP');
  
  builder.row('FACTURE N°', InvoicePrintHelpers.truncateId(sale.id));
  builder.row('Date', InvoicePrintHelpers.formatDate(sale.date));
  builder.row('Heure', InvoicePrintHelpers.formatTime(sale.date));
  builder.space();

  // Client
  builder.row('Client', sale.customerName);
  if (sale.customerPhone.isNotEmpty) {
    builder.row('Tel', sale.customerPhone);
  }
  builder.space();

  // Détails
  builder.section('Détail Achat');
  
  final priceDetail = '${sale.quantity}x ${InvoicePrintHelpers.formatCurrency(sale.unitPrice)}';
  final totalDetail = InvoicePrintHelpers.formatCurrency(sale.totalPrice);
  builder.itemRow(sale.productName, priceDetail, totalDetail);
  builder.separator();

  // Totaux
  builder.total('TOTAL', InvoicePrintHelpers.formatCurrency(sale.totalPrice));
  builder.row('Payé', InvoicePrintHelpers.formatCurrency(sale.amountPaid));

  if (sale.cashAmount > 0) {
    builder.row('  Cash', InvoicePrintHelpers.formatCurrency(sale.cashAmount));
  }
  if (sale.orangeMoneyAmount > 0) {
    builder.row('  OM', InvoicePrintHelpers.formatCurrency(sale.orangeMoneyAmount));
  }

  if (sale.remainingAmount > 0) {
    builder.space();
    builder.row('RESTE A PAYER', InvoicePrintHelpers.formatCurrency(sale.remainingAmount));
  }

  // Pied de page
  builder.footer('Merci !');

  return builder.toString();
}

/// Génère le contenu texte pour l'imprimante thermique (paiement crédit).
String generateCreditPaymentReceipt({
  required String customerName,
  required Sale sale,
  required int paymentAmount,
  required int remainingAfterPayment,
  String? notes,
  int cashAmount = 0,
  int omAmount = 0,
}) {
  final builder = ThermalReceiptBuilder(width: 32);
  final now = DateTime.now();
  final newAmountPaid = sale.amountPaid + paymentAmount;

  // Entête moderne et centré
  builder.header('EAU MINERALE ELYF', subtitle: 'REÇU DE PAIEMENT');

  builder.row('Date', InvoicePrintHelpers.formatDate(now));
  builder.row('Heure', InvoicePrintHelpers.formatTime(now));
  builder.row('Client', customerName);
  builder.space();

  // Info Vente
  builder.section('Référence Vente');
  builder.row('Date vente', InvoicePrintHelpers.formatDate(sale.date));
  builder.row('Article', '${sale.productName} x${sale.quantity}');
  builder.row('Total vente', InvoicePrintHelpers.formatCurrency(sale.totalPrice));
  builder.space();

  // Info Paiement
  builder.section('Détail Paiement');
  builder.row('Déjà payé', InvoicePrintHelpers.formatCurrency(sale.amountPaid));
  builder.row('PAIEMENT', InvoicePrintHelpers.formatCurrency(paymentAmount));
  
  if (cashAmount > 0) {
    builder.row('  Cash', InvoicePrintHelpers.formatCurrency(cashAmount));
  }
  if (omAmount > 0) {
    builder.row('  OM', InvoicePrintHelpers.formatCurrency(omAmount));
  }

  builder.separator();
  builder.total('TOTAL PAYÉ', InvoicePrintHelpers.formatCurrency(newAmountPaid));
  
  if (remainingAfterPayment > 0) {
    builder.row('Reste', InvoicePrintHelpers.formatCurrency(remainingAfterPayment));
  } else {
    builder.space();
    builder.center('*** SOLDE ***');
  }

  if (notes != null && notes.isNotEmpty) {
    builder.space();
    builder.writeLine('Note: $notes');
  }

  // Pied de page
  builder.footer('Merci !');

  return builder.toString();
}
