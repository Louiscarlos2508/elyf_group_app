
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../core/printing/printer_provider.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/payment.dart';
import 'package:elyf_groupe_app/core/printing/templates/payment_receipt_template.dart';
import 'package:elyf_groupe_app/features/immobilier/presentation/widgets/payment_card_helpers.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

/// Bouton d'impression de facture supportant plusieurs types d'imprimantes via activePrinterProvider.
class PrintReceiptButton extends ConsumerStatefulWidget {
  const PrintReceiptButton({
    super.key,
    this.sale,
    this.payment,
    this.onPrintSuccess,
    this.onPrintError,
    this.iconOnly = false,
  }) : assert(sale != null || payment != null, 'Either sale or payment must be provided');

  final Sale? sale;
  final Payment? payment;
  final VoidCallback? onPrintSuccess;
  final void Function(String error)? onPrintError;
  final bool iconOnly;

  @override
  ConsumerState<PrintReceiptButton> createState() => _PrintReceiptButtonState();
}

class _PrintReceiptButtonState extends ConsumerState<PrintReceiptButton> {
  bool _isPrinting = false;
  bool _isPrinterAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkPrinterAvailability();
  }

  Future<void> _checkPrinterAvailability() async {
    final printer = ref.read(activePrinterProvider);
    final isAvailable = await printer.isAvailable();

    if (mounted) {
      setState(() {
        _isPrinterAvailable = isAvailable;
      });
    }
  }

  Future<void> _printReceipt() async {
    final printer = ref.read(activePrinterProvider);
    final isAvailable = await printer.isAvailable();
    
    if (!isAvailable) {
      if (mounted) {
        NotificationService.showWarning(context, 'Imprimante non disponible. Vérifiez les réglages.');
      }
      widget.onPrintError?.call('Imprimante non disponible');
      return;
    }

    setState(() => _isPrinting = true);

    try {
      final width = await printer.getLineWidth();
      String content = '';

      if (widget.sale != null) {
        final template = SalesReceiptTemplate(
          widget.sale!,
          width: width,
          headerText: 'BOUTIQUE ELYF',
          footerText: 'Merci de votre visite !',
          showLogo: true,
        );
        content = template.generate();
      } else if (widget.payment != null) {
        final payment = widget.payment!;
        content = PaymentReceiptTemplate.generateReceipt(
          receiptNumber: payment.receiptNumber ?? payment.id.substring(0, 8),
          paymentDate: DateFormatter.formatDate(payment.paymentDate),
          amount: CurrencyFormatter.format(payment.amount),
          paymentMethod: payment.paymentMethod.label,
          tenantName: payment.contract?.tenant?.fullName ?? 'Locataire',
          propertyAddress: payment.contract?.property?.address ?? 'Propriété',
          period: payment.month != null && payment.year != null 
              ? '${PaymentCardHelpers.getMonthName(payment.month!)} ${payment.year}'
              : null,
          header: 'ELYF IMMOBILIER',
          footer: 'Merci de votre confiance !',
        );
      }
      
      final success = await printer.printReceipt(content);

      if (!mounted) return;

      if (success) {
        widget.onPrintSuccess?.call();
        NotificationService.showSuccess(context, 'Facture imprimée avec succès');
      } else {
        widget.onPrintError?.call('Erreur lors de l\'impression');
        NotificationService.showError(context, 'Erreur lors de l\'impression');
      }
    } catch (e) {
      if (!mounted) return;
      widget.onPrintError?.call(e.toString());
      NotificationService.showError(context, 'Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.iconOnly) {
      return IconButton(
        icon: _isPrinting 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.print_outlined, size: 20),
        onPressed: _isPrinting ? null : _printReceipt,
        tooltip: 'Imprimer ticket',
        color: _isPrinterAvailable ? Colors.blue : Colors.grey,
      );
    }

    final theme = Theme.of(context);

    return FilledButton.icon(
      onPressed: _isPrinting ? null : _printReceipt,
      icon: _isPrinting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.print),
      label: Text(_isPrinting ? 'Impression...' : 'Imprimer la facture'),
      style: FilledButton.styleFrom(
        backgroundColor: _isPrinterAvailable
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
