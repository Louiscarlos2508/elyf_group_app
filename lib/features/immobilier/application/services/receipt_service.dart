import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/printing/printer_provider.dart';
import '../../../../core/printing/templates/payment_receipt_template.dart';
import '../../../../shared/domain/entities/payment_method.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/tenant.dart';

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService(ref);
});

class ReceiptService {
  ReceiptService(this._ref);

  final Ref _ref;

  Future<bool> printReceipt({
    required Payment payment,
    required Tenant tenant,
    required Property property,
  }) async {
    final printer = _ref.read(activePrinterProvider);

    // Note: isAvailable check might be blocking for system printers that are always "available"
    // but for bluetooth/sunmi it checks connection.
    // If it returns false, the UI should probably inform the user.
    if (!await printer.isAvailable()) {
      return false;
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final amountFormat = NumberFormat('#,###', 'fr_FR');

    String period = '';
    if (payment.paymentType == PaymentType.deposit) {
      period = 'Caution / Dépôt de garantie';
    } else if (payment.month != null && payment.year != null) {
      // Create a date to format the month name
      // Use day 1 to avoid overflow issues
      final date = DateTime(payment.year!, payment.month!, 1);
      // Capitalize first letter
      final monthName = DateFormat('MMMM', 'fr_FR').format(date);
      period = '${monthName[0].toUpperCase()}${monthName.substring(1)} ${payment.year}';
    }

    final content = PaymentReceiptTemplate.generateReceipt(
      receiptNumber: payment.receiptNumber ?? payment.id.substring(0, 8),
      paymentDate: dateFormat.format(payment.paymentDate),
      amount: amountFormat.format(payment.amount),
      paymentMethod: _formatPaymentMethod(payment.paymentMethod),
      tenantName: tenant.fullName,
      propertyAddress: '${property.address}, ${property.city}',
      period: period.isNotEmpty ? period : null,
      notes: payment.notes,
    );

    return await printer.printReceipt(content);
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.both:
        return 'Espèces + Mobile Money';
    }
  }
}
