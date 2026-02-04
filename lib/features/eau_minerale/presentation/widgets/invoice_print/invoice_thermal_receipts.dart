import '../../../domain/entities/sale.dart';
import 'invoice_print_helpers.dart';

/// Génère le contenu texte pour l'imprimante thermique (vente).
String generateSaleReceipt(Sale sale) {
  final buffer = StringBuffer();
  const width = 32;

  String center(String text) {
    if (text.length >= width) return text.substring(0, width);
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  String separator() => center('--------------------------------');

  // Entête moderne et centré
  buffer.writeln(center('EAU MINERALE ELYF'));
  buffer.writeln(center('GROUPE APP'));
  buffer.writeln(separator());
  
  buffer.writeln(center('FACTURE N°: ${InvoicePrintHelpers.truncateId(sale.id)}'));
  buffer.writeln(center('${InvoicePrintHelpers.formatDate(sale.date)} ${InvoicePrintHelpers.formatTime(sale.date)}'));
  
  buffer.writeln(separator());

  // Client centré
  buffer.writeln(center('Client: ${sale.customerName}'));
  if (sale.customerPhone.isNotEmpty) {
    buffer.writeln(center('Tel: ${sale.customerPhone}'));
  }
  buffer.writeln();

  // Détails
  buffer.writeln(separator());
  buffer.writeln('Article: ${sale.productName}');
  buffer.writeln(
    'Qte: ${sale.quantity} x '
    '${InvoicePrintHelpers.formatCurrency(sale.unitPrice)}',
  );
  buffer.writeln(separator());
  buffer.writeln();

  // Totaux
  buffer.writeln('TOTAL: ${InvoicePrintHelpers.formatCurrency(sale.totalPrice)}');
  buffer.writeln('Paye:  ${InvoicePrintHelpers.formatCurrency(sale.amountPaid)}');

  if (sale.cashAmount > 0) {
    buffer.writeln('  Cash: ${InvoicePrintHelpers.formatCurrency(sale.cashAmount)}');
  }
  if (sale.orangeMoneyAmount > 0) {
    buffer.writeln('  OM:   ${InvoicePrintHelpers.formatCurrency(sale.orangeMoneyAmount)}');
  }

  if (sale.remainingAmount > 0) {
    buffer.writeln();
    buffer.writeln('CREDIT: ${InvoicePrintHelpers.formatCurrency(sale.remainingAmount)}');
  }

  buffer.writeln();
  buffer.writeln(separator());
  buffer.writeln(center('Merci !'));
  buffer.writeln('\n\n'); 

  return buffer.toString();
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
  final buffer = StringBuffer();
  const width = 32;

  String center(String text) {
    if (text.length >= width) return text.substring(0, width);
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  String separator() => center('--------------------------------');
  final now = DateTime.now();
  final newAmountPaid = sale.amountPaid + paymentAmount;

  // Entête moderne et centré
  buffer.writeln(center('EAU MINERALE ELYF'));
  buffer.writeln(center('RECU DE PAIEMENT'));
  buffer.writeln(separator());

  buffer.writeln(center('${InvoicePrintHelpers.formatDate(now)} ${InvoicePrintHelpers.formatTime(now)}'));
  buffer.writeln(center('Client: $customerName'));
  buffer.writeln(separator());

  // Info Vente
  buffer.writeln('Ref vente: ${InvoicePrintHelpers.formatDate(sale.date)}');
  buffer.writeln('${sale.productName} x${sale.quantity}');
  buffer.writeln('Total vente: ${InvoicePrintHelpers.formatCurrency(sale.totalPrice)}');
  buffer.writeln(separator());

  // Info Paiement
  buffer.writeln('Deja paye:  ${InvoicePrintHelpers.formatCurrency(sale.amountPaid)}');
  buffer.writeln('PAIEMENT:   ${InvoicePrintHelpers.formatCurrency(paymentAmount)}');
  
  if (cashAmount > 0) {
    buffer.writeln('  Cash: ${InvoicePrintHelpers.formatCurrency(cashAmount)}');
  }
  if (omAmount > 0) {
    buffer.writeln('  OM:   ${InvoicePrintHelpers.formatCurrency(omAmount)}');
  }

  buffer.writeln('Total paye: ${InvoicePrintHelpers.formatCurrency(newAmountPaid)}');
  
  if (remainingAfterPayment > 0) {
    buffer.writeln('Reste:      ${InvoicePrintHelpers.formatCurrency(remainingAfterPayment)}');
  } else {
    buffer.writeln();
    buffer.writeln(center('*** SOLDE ***'));
  }

  if (notes != null && notes.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('Note: $notes');
  }

  buffer.writeln();
  buffer.writeln(separator());
  buffer.writeln(center('Merci !'));
  buffer.writeln('\n\n');

  return buffer.toString();
}
