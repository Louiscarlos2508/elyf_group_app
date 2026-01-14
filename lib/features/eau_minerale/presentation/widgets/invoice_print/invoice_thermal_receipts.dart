import '../../../domain/entities/sale.dart';
import 'invoice_print_helpers.dart';

/// Génère le contenu texte pour l'imprimante thermique (vente).
String generateSaleReceipt(Sale sale) {
  final buffer = StringBuffer();

  // Entête compact
  buffer.write('================================\n');
  buffer.write('      EAU MINERALE ELYF\n');
  buffer.write('================================\n');
  buffer.write('FACTURE: ${InvoicePrintHelpers.truncateId(sale.id)}\n');
  buffer.write(
    'Date: ${InvoicePrintHelpers.formatDate(sale.date)} '
    '${InvoicePrintHelpers.formatTime(sale.date)}\n',
  );
  buffer.write('--------------------------------\n');
  buffer.write('Client: ${sale.customerName}\n');
  if (sale.customerPhone.isNotEmpty) {
    buffer.write('Tel: ${sale.customerPhone}\n');
  }
  buffer.write('--------------------------------\n');
  buffer.write('Article: ${sale.productName}\n');
  buffer.write(
    'Qte: ${sale.quantity} x '
    '${InvoicePrintHelpers.formatCurrency(sale.unitPrice)}\n',
  );
  buffer.write('--------------------------------\n');
  buffer.write(
    'TOTAL: ${InvoicePrintHelpers.formatCurrency(sale.totalPrice)}\n',
  );
  buffer.write(
    'Paye: ${InvoicePrintHelpers.formatCurrency(sale.amountPaid)}\n',
  );

  if (sale.cashAmount > 0) {
    buffer.write(
      '  Cash: ${InvoicePrintHelpers.formatCurrency(sale.cashAmount)}\n',
    );
  }
  if (sale.orangeMoneyAmount > 0) {
    buffer.write(
      '  OM: ${InvoicePrintHelpers.formatCurrency(sale.orangeMoneyAmount)}\n',
    );
  }

  if (sale.remainingAmount > 0) {
    buffer.write(
      'CREDIT: ${InvoicePrintHelpers.formatCurrency(sale.remainingAmount)}\n',
    );
  }

  buffer.write('================================\n');
  buffer.write('        Merci!\n');

  return buffer.toString();
}

/// Génère le contenu texte pour l'imprimante thermique (paiement crédit).
String generateCreditPaymentReceipt({
  required String customerName,
  required Sale sale,
  required int paymentAmount,
  required int remainingAfterPayment,
  String? notes,
}) {
  final buffer = StringBuffer();
  final now = DateTime.now();
  final newAmountPaid = sale.amountPaid + paymentAmount;

  // Entête compact
  buffer.write('================================\n');
  buffer.write('      EAU MINERALE ELYF\n');
  buffer.write('      RECU DE PAIEMENT\n');
  buffer.write('================================\n');
  buffer.write(
    'Date: ${InvoicePrintHelpers.formatDate(now)} '
    '${InvoicePrintHelpers.formatTime(now)}\n',
  );
  buffer.write('Client: $customerName\n');
  buffer.write('--------------------------------\n');
  buffer.write('Ref vente: ${InvoicePrintHelpers.formatDate(sale.date)}\n');
  buffer.write('${sale.productName} x${sale.quantity}\n');
  buffer.write(
    'Total vente: ${InvoicePrintHelpers.formatCurrency(sale.totalPrice)}\n',
  );
  buffer.write('--------------------------------\n');
  buffer.write(
    'Deja paye: ${InvoicePrintHelpers.formatCurrency(sale.amountPaid)}\n',
  );
  buffer.write(
    'PAIEMENT: ${InvoicePrintHelpers.formatCurrency(paymentAmount)}\n',
  );
  buffer.write(
    'Total paye: ${InvoicePrintHelpers.formatCurrency(newAmountPaid)}\n',
  );
  if (remainingAfterPayment > 0) {
    buffer.write(
      'Reste: ${InvoicePrintHelpers.formatCurrency(remainingAfterPayment)}\n',
    );
  } else {
    buffer.write('*** SOLDE ***\n');
  }

  if (notes != null && notes.isNotEmpty) {
    buffer.write('Note: $notes\n');
  }

  buffer.write('================================\n');
  buffer.write('        Merci!\n');

  return buffer.toString();
}
