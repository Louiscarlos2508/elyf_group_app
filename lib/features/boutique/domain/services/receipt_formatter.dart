import 'package:intl/intl.dart';
import '../entities/sale.dart';

class ReceiptFormatter {
  static String formatReceipt(Sale sale, {int lineWidth = 32}) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat('#,###');

    // Header
    buffer.writeln('ELYF BOUTIQUE');
    buffer.writeln('FACTURE N: ${sale.number ?? sale.id.substring(0, 8).toUpperCase()}');
    buffer.writeln('Date: ${dateFormat.format(sale.date)}');
    if (sale.customerName != null) {
      buffer.writeln('Client: ${sale.customerName}');
    }
    buffer.writeln('-' * lineWidth);

    // Items
    buffer.writeln('DESIG.   QTÉ   P.U   TOTAL');
    for (final item in sale.items) {
      final name = item.productName.length > 10 
          ? item.productName.substring(0, 7) + '..' 
          : item.productName.padRight(10);
      
      final qty = item.quantity.toString().padRight(4);
      final price = currencyFormat.format(item.unitPrice).padLeft(6);
      final total = currencyFormat.format(item.totalPrice).padLeft(8);
      
      buffer.writeln('$name $qty $price $total');
    }

    buffer.writeln('-' * lineWidth);

    // Totals
    buffer.writeln('TOTAL: ${currencyFormat.format(sale.totalAmount)} CFA'.padLeft(lineWidth));
    buffer.writeln('PAYé: ${currencyFormat.format(sale.amountPaid)} CFA'.padLeft(lineWidth));
    
    if (sale.change > 0) {
      buffer.writeln('RENDU: ${currencyFormat.format(sale.change)} CFA'.padLeft(lineWidth));
    }

    buffer.writeln('-' * lineWidth);
    
    // Payment Methods
    if (sale.paymentMethod != null) {
      buffer.writeln('Mode: ${sale.paymentMethod!.name.toUpperCase()}');
    }

    buffer.writeln('\nMerci de votre confiance !');
    buffer.writeln('ELYF Group - Scalario POS');
    buffer.writeln('\n\n'); // Feed space

    return buffer.toString();
  }
}
